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

final class DelugeTorrentListViewModel: TorrentListViewModel, DelugeRefreshable {
    private let client: DelugeClient
    private let preferences: Preferences
    private let torrents = TorrentSubjectMapManager<String, DelugeTorrent>()
    private let eventSubject = PassthroughSubject<TorrentListEvent, Never>()
    private var autoUpdateTimer: Timer?
    let items: AnyPublisher<[AnyTorrentListItemViewModel], Never>
    let showAddButton = true
    var observers = [AnyCancellable]()

    var events: AnyPublisher<TorrentListEvent, Never> {
        return eventSubject.eraseToAnyPublisher()
    }

    init(client: DelugeClient, preferences: Preferences) {
        self.client = client
        self.preferences = preferences

        items = torrents.sorted
            .map { $0.map { DelugeTorrentListItemViewModel(torrentSubject: $0).eraseToAny() } }
            .removeDuplicates()
            .ui()
            .eraseToAnyPublisher()

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

    func refreshTorrents() -> AnyPublisher<Void, DelugeError> {
        return client.fetchTorrents()
            .handleEvents(receiveOutput: { [weak self] new in
                self?.torrents.update(with: new.map { ($0.hash, $0) })
            })
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    func refresh() -> AnyPublisher<Void, Error> {
        return refreshTorrents()
            .mapError { $0 as Error }
            .ui()
            .handleEvents(receiveCompletion: { [weak self] completion in
                guard case let .failure(error) = completion else { return }
                self?.showError(title: "Update Failed", message: error.localizedDescription)
            })
            .eraseToAnyPublisher()
    }

    func didSelectAdd(from source: PopoverSource) {
        eventSubject.send(.add(source: source))
    }

    func didSelectItem(at index: Int) {
        let subject = torrents.subject(at: index)
        let viewModel = DelugeTorrentDetailViewModel(
            torrentSubject: subject,
            client: client,
            preferences: preferences,
            refresher: self
        )
        eventSubject.send(.detail(viewModel: AnyProducerViewModel(viewModel)))
    }

    func didSelectSettings() {
        eventSubject.send(.settings)
    }

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
