//
//  StandardTorrentListViewModel.swift
//  Magnesium
//
//  Created by James Hurst on 2020-02-06.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import Foundation
import Preferences
import UIKit
import ViewModel

protocol StandardTorrentListViewModelImplementation {
    associatedtype Torrent: StandardTorrent
    associatedtype Label: StandardLabel
    var updated: AnyPublisher<([Torrent], [Label]), Never> { get }
    func refresh() -> AnyPublisher<([Torrent], [Label]), Error>
    func detailViewModel(
        for subject: CurrentValueSubject<Torrent, Never>,
        labels: CurrentValueSubject<[Label], Never>
    ) -> AnyTorrentDetailViewModel
    func addLink(_ url: String) -> AnyPublisher<(String, String), Never>
    func pause(_ torrent: Torrent) -> AnyPublisher<Void, Error>
    func resume(_ torrent: Torrent) -> AnyPublisher<Void, Error>
    func remove(_ torrent: Torrent, removeData: Bool) -> AnyPublisher<Void, Error>
    func setLabel(_ label: Label, for torrent: Torrent) -> AnyPublisher<Void, Error>
}

// swiftlint:disable:next line_length
final class StandardTorrentListViewModel<Implementation: StandardTorrentListViewModelImplementation>: ViewModel, EventEmitter, TorrentListPreviewProvider {
    typealias Torrent = Implementation.Torrent
    typealias Label = Implementation.Label

    private let implementation: Implementation
    private let preferences: Preferences
    private let torrents: TorrentMapper<String, Torrent>
    private let labels = CurrentValueSubject<[Label], Never>([])
    private let isLoadingSubject = CurrentValueSubject<Bool, Never>(false)
    private let eventSubject = PassthroughSubject<TorrentListEvent, Never>()
    private var autoRefreshTimer: Timer?
    let state: TorrentListViewState
    var observers = [AnyCancellable]()

    var events: AnyPublisher<TorrentListEvent, Never> {
        return eventSubject.eraseToAnyPublisher()
    }

    init(implementation: Implementation, preferences: Preferences) {
        self.preferences = preferences
        torrents = TorrentMapper(preferences: preferences)
        self.implementation = implementation

        let items = torrents.values
            .map { $0.map { AnyViewModel(StandardTorrentListItemViewModel(subject: $0)) } }
            .removeDuplicates { $0.map { $0.id } == $1.map { $0.id } }
            .ui()
            .eraseToAnyPublisher()
        state = TorrentListViewState(items: items, isLoading: isLoadingSubject.eraseToAnyPublisher())

        refresh()
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &observers)

        preferences.valuePublisher(for: PreferenceKeys.autoRefreshInterval)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] value in
                self?.configureAutoRefreshTimer(interval: value)
            })
            .store(in: &observers)

        implementation.updated
            .sink { [weak self] update in
                self?.labels.send(update.1)
                self?.torrents.update(with: update.0.map { ($0.hash, $0) })
            }
            .store(in: &observers)
    }

    deinit {
        autoRefreshTimer?.invalidate()
    }

    func handle(_ event: TorrentListViewEvent) {
        switch event {
        case .refresh:
            guard !isLoadingSubject.value else { return }
            isLoadingSubject.send(true)
            refresh()
                .sink(receiveCompletion: { [weak self] _ in
                    self?.isLoadingSubject.send(false)
                    }, receiveValue: { _ in })
                .store(in: &observers)

        case let .addSelected(source):
            let linkSubject = PassthroughSubject<String, Never>()
            linkSubject
                .sink { [weak self] in self?.addLink($0) }
                .store(in: &observers)
            eventSubject.send(.add(source: source, linkSubject: linkSubject))

        case let .filterSelected(source):
            let mappedLabels = CurrentValueSubject<[StandardLabel], Never>(labels.value)
            labels.sink { [weak mappedLabels] in mappedLabels?.send($0) }.store(in: &observers)
            eventSubject.send(.filter(source: source, labels: mappedLabels))

        case let .itemSelected(index):
            let subject = torrents.subject(at: index)
            let viewModel = implementation.detailViewModel(for: subject, labels: labels)
            eventSubject.send(.detail(viewModel: viewModel))

        case .settingsSelected:
            eventSubject.send(.settings)
        }
    }

    // internal for testing
    func addLink(_ url: String) {
        implementation.addLink(url)
            .ui()
            .sink { [weak self] title, message in
                self?.showError(title: title, message: message)
            }
            .store(in: &observers)
    }

    private func configureAutoRefreshTimer(interval: TimeInterval?) {
        autoRefreshTimer?.invalidate()
        guard let interval = interval, interval > 0 else { return }
        let timer = Timer(fire: Date().advanced(by: interval), interval: interval, repeats: true) { [weak self] in
            self?.refreshTimerFired($0)
        }
        RunLoop.main.add(timer, forMode: .common)
        autoRefreshTimer = timer
    }

    private func refreshTimerFired(_ timer: Timer) {
        performRefresh()
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &observers)
    }

    private func refresh() -> AnyPublisher<Void, Error> {
        return performRefresh()
            .mapError { $0 as Error }
            .ui()
            .handleEvents(receiveCompletion: { [weak self] completion in
                guard case let .failure(error) = completion else { return }
                self?.showError(title: "Update Failed", message: error.localizedDescription)
            })
            .eraseToAnyPublisher()
    }

    private func performRefresh() -> AnyPublisher<Void, Error> {
        return implementation.refresh()
            .handleEvents(receiveOutput: { [weak self] update in
                self?.labels.send(update.1)
                self?.torrents.update(with: update.0.map { ($0.hash, $0) })
            })
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    private func showError(title: String, message: String?) {
        var alert = Alert(
            title: title,
            message: message,
            style: .alert
        )
        alert.addAction(AlertAction(title: "OK", style: .default))
        eventSubject.send(.alert(alert, source: nil))
    }

    // MARK: TorrentListPreviewProvider

    func detailViewModelForItem(at index: Int) -> AnyTorrentDetailViewModel? {
        let subject = torrents.subject(at: index)
        return implementation.detailViewModel(for: subject, labels: labels)
    }

    func contextMenuForItem(at index: Int) -> UIMenu? {
        let torrent = torrents.subject(at: index).value
        var actions = [UIMenuElement]()

        if !labels.value.isEmpty {
            actions.append(UIMenu(
                title: "Set Label",
                image: UIImage(systemName: "square.and.pencil"),
                children: labels.value.map { label in
                    UIAction(title: label.displayName) { [weak self] _ in
                        self?.handleSetLabelAction(for: torrent, label: label)
                    }
                }
            ))
        }

        if torrent.isActive {
            actions.append(UIAction(title: "Pause", image: UIImage(systemName: "pause")) { [weak self] _ in
                self?.handlePauseAction(for: torrent)
            })
        } else {
            actions.append(UIAction(title: "Resume", image: UIImage(systemName: "play")) { [weak self] _ in
                self?.handleResumeAction(for: torrent)
            })
        }

        actions.append(UIMenu(
            title: "Remove",
            image: UIImage(systemName: "trash"),
            options: .destructive,
            children: [
                UIAction(title: "Keep Data", image: UIImage(systemName: "trash")) { [weak self] _ in
                    self?.handleRemoveAction(for: torrent, removeData: false)
                },
                UIAction(
                    title: "Remove Data",
                    image: UIImage(systemName: "trash"),
                    attributes: .destructive
                ) { [weak self] _ in
                    self?.handleRemoveAction(for: torrent, removeData: true)
                },
            ]
        ))

        return UIMenu(title: "", children: actions)
    }

    // internal for testing
    func handleSetLabelAction(for torrent: Torrent, label: Label) {
        implementation.setLabel(label, for: torrent)
            .handleEvents(receiveCompletion: { [weak self] completion in
                guard let strongSelf = self, case .finished = completion else { return }
                strongSelf.implementation.refresh()
                    .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
                    .store(in: &strongSelf.observers)
            })
            .ui()
            .sink(receiveCompletion: { [weak self] completion in
                guard case let .failure(error) = completion else { return }
                self?.showError(
                    title: "Failed to Set Label for \"\(torrent.name)\"",
                    message: error.localizedDescription
                )
                }, receiveValue: { _ in })
            .store(in: &observers)
    }

    // internal for testing
    func handlePauseAction(for torrent: Torrent) {
        implementation.pause(torrent)
            .handleEvents(receiveCompletion: { [weak self] completion in
                guard let strongSelf = self, case .finished = completion else { return }
                strongSelf.implementation.refresh()
                    .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
                    .store(in: &strongSelf.observers)
            })
            .ui()
            .sink(receiveCompletion: { [weak self] completion in
                guard case let .failure(error) = completion else { return }
                self?.showError(title: "Failed to Pause \"\(torrent.name)\"", message: error.localizedDescription)
                }, receiveValue: { _ in })
            .store(in: &observers)
    }

    // internal for testing
    func handleResumeAction(for torrent: Torrent) {
        implementation.resume(torrent)
            .handleEvents(receiveCompletion: { [weak self] completion in
                guard let strongSelf = self, case .finished = completion else { return }
                strongSelf.implementation.refresh()
                    .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
                    .store(in: &strongSelf.observers)
            })
            .ui()
            .sink(receiveCompletion: { [weak self] completion in
                guard case let .failure(error) = completion else { return }
                self?.showError(title: "Failed to Resume \"\(torrent.name)\"", message: error.localizedDescription)
                }, receiveValue: { _ in })
            .store(in: &observers)
    }

    // internal for testing
    func handleRemoveAction(for torrent: Torrent, removeData: Bool) {
        implementation.remove(torrent, removeData: removeData)
            .handleEvents(receiveCompletion: { [weak self] completion in
                guard let strongSelf = self, case .finished = completion else { return }
                strongSelf.implementation.refresh()
                    .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
                    .store(in: &strongSelf.observers)
            })
            .ui()
            .sink(receiveCompletion: { [weak self] completion in
                guard case let .failure(error) = completion else { return }
                self?.showError(title: "Failed to Remove \"\(torrent.name)\"", message: error.localizedDescription)
                }, receiveValue: { _ in })
            .store(in: &observers)
    }
}
