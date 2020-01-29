//
//  DelugeTorrentListViewModel.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-07.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import Foundation
import Preferences

final class DelugeTorrentListViewModel: ViewModel, EventProducer, DelugeRefreshable {
    private let client: DelugeClient
    private let preferences: Preferences
    private let torrents = TorrentSubjectMapManager<String, DelugeTorrent>()
    private let isLoadingSubject = CurrentValueSubject<Bool, Never>(false)
    private let eventSubject = PassthroughSubject<TorrentListEvent, Never>()
    private var autoUpdateTimer: Timer?
    let state: TorrentListViewState
    var observers = [AnyCancellable]()

    var events: AnyPublisher<TorrentListEvent, Never> {
        return eventSubject.eraseToAnyPublisher()
    }

    init(client: DelugeClient, preferences: Preferences) {
        self.client = client
        self.preferences = preferences

        let items = torrents.sorted
            .map { $0.map { AnyViewModel(DelugeTorrentListItemViewModel(subject: $0)) } }
            .removeDuplicates { $0.map { $0.id } != $1.map { $0.id } }
            .ui()
            .eraseToAnyPublisher()
        state = TorrentListViewState(items: items, isLoading: isLoadingSubject.eraseToAnyPublisher())

        refresh()
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &observers)

        preferences.valuePublisher(for: PreferenceKeys.autoRefreshInterval)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] value in
                self?.configureAutoUpdateTimer(interval: value)
            })
            .store(in: &observers)
    }

    deinit {
        autoUpdateTimer?.invalidate()
    }

    func handle(_ event: TorrentListViewEvent) {
        switch event {
        case let .add(source):
            let linkSubject = PassthroughSubject<String, Never>()
            linkSubject
                .sink { [weak self] in self?.addLink($0) }
                .store(in: &observers)
            eventSubject.send(.add(source: source, linkSubject: linkSubject))

        case .refresh:
            guard !isLoadingSubject.value else { return }
            isLoadingSubject.send(false)
            refresh()
                .sink(receiveCompletion: { [weak self] _ in
                    self?.isLoadingSubject.send(false)
                    }, receiveValue: { _ in })
                .store(in: &observers)

        case let .selectItem(index):
            let subject = torrents.subject(at: index)
            let viewModel = DelugeTorrentDetailViewModel(
                subject: subject,
                client: client,
                preferences: preferences,
                refresher: self
            )
            eventSubject.send(.detail(viewModel: AnyProducerViewModel(viewModel)))

        case .settings:
            eventSubject.send(.settings)
        }
    }

    private func configureAutoUpdateTimer(interval: TimeInterval?) {
        autoUpdateTimer?.invalidate()
        guard let interval = interval, interval > 0 else { return }
        let timer = Timer(fire: Date().advanced(by: interval), interval: interval, repeats: true) { [weak self] in
            self?.updateTimerFired($0)
        }
        RunLoop.main.add(timer, forMode: .common)
        autoUpdateTimer = timer
    }

    private func updateTimerFired(_ timer: Timer) {
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

    func refreshTorrents() -> AnyPublisher<Void, DelugeError> {
        return client.fetchTorrents()
            .handleEvents(receiveOutput: { [weak self] new in
                self?.torrents.update(with: new.map { ($0.hash, $0) })
            })
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    // internal for testing
    func addLink(_ url: String) {
        guard let url = URL(string: url) else {
            showError(title: "Unable to Add Link", message: "That link doesn't appear to be valid.")
            return
        }

        let publisher: AnyPublisher<Void, DelugeError>

        if url.scheme == "magnet" {
            publisher = client.add(magnetURL: url)
        } else {
            publisher = client.add(url: url)
        }

        publisher
            .ui()
            .sink(receiveCompletion: { [weak self] completion in
                guard case let .failure(error) = completion else { return }
                self?.showError(title: "Failed to Add Torrent", message: error.localizedDescription)
            }, receiveValue: { _ in })
            .store(in: &observers)
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
