//
//  TorrentListViewModel.swift
//  Magnesium
//
//  Created by James Hurst on 2019-11-12.
//  Copyright © 2019 James Hurst. All rights reserved.
//

import Combine
import Foundation
import Preferences
import ViewModel

typealias AnyTorrentListViewModel = AnyEmitterViewModel<TorrentListEvent, TorrentListViewEvent, TorrentListViewState>

enum TorrentListEvent {
    case alert(Alert, source: PopoverSource?)
    case add(source: PopoverSource, linkSubject: PassthroughSubject<String, Never>)
    case filter(source: PopoverSource)
    case detail(viewModel: AnyTorrentDetailViewModel)
    case settings
}

enum TorrentListViewEvent {
    case refresh
    case addSelected(source: PopoverSource)
    case filterSelected(source: PopoverSource)
    case itemSelected(index: Int)
    case settingsSelected
}

struct TorrentListViewState {
    var showAddButton: Bool = true
    var items: AnyPublisher<[AnyTorrentListItemViewModel], Never>
    var isLoading: AnyPublisher<Bool, Never>
}

protocol StandardTorrentListViewModelImplementation {
    associatedtype Torrent: StandardTorrent
    var torrentsUpdated: AnyPublisher<[Torrent], Never> { get }
    func refresh() -> AnyPublisher<[Torrent], Error>
    func detailViewModel(for subject: CurrentValueSubject<Torrent, Never>) -> AnyTorrentDetailViewModel
    func addLink(_ url: String) -> AnyPublisher<(String, String), Never>
}

// swiftlint:disable:next line_length
final class StandardTorrentListViewModel<Implementation: StandardTorrentListViewModelImplementation>: ViewModel, EventEmitter {
    typealias Torrent = Implementation.Torrent

    private let implementation: Implementation
    private let preferences: Preferences
    private let torrents: TorrentMapper<String, Torrent>
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

        implementation.torrentsUpdated
            .sink { [weak self] torrents in
                self?.torrents.update(with: torrents.map { ($0.hash, $0) })
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

        case let .addSelected(source: source):
            let linkSubject = PassthroughSubject<String, Never>()
            linkSubject
                .sink { [weak self] in self?.addLink($0) }
                .store(in: &observers)
            eventSubject.send(.add(source: source, linkSubject: linkSubject))

        case let .filterSelected(source: source):
            eventSubject.send(.filter(source: source))

        case let .itemSelected(index: index):
            let subject = torrents.subject(at: index)
            let viewModel = implementation.detailViewModel(for: subject)
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
        refreshTorrents()
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &observers)
    }

    private func refresh() -> AnyPublisher<Void, Error> {
        return refreshTorrents()
            .mapError { $0 as Error }
            .ui()
            .handleEvents(receiveCompletion: { [weak self] completion in
                guard case let .failure(error) = completion else { return }
                self?.showError(title: "Update Failed", message: error.localizedDescription)
            })
            .eraseToAnyPublisher()
    }

    private func refreshTorrents() -> AnyPublisher<Void, Error> {
        return implementation.refresh()
            .handleEvents(receiveOutput: { [weak self] new in
                self?.torrents.update(with: new.map { ($0.hash, $0) })
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
}
