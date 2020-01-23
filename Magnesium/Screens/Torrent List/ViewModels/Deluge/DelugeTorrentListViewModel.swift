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
    private var autoUpdateTimer: Timer?
    private(set) weak var coordinator: TorrentListCoordinator?
    let items: AnyPublisher<[AnyTorrentListItemViewModel], Never>
    var observers = [AnyCancellable]()

    init(coordinator: TorrentListCoordinator, client: DelugeClient, preferences: Preferences) {
        self.coordinator = coordinator
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
            .handleEvents(receiveOutput: { new in
                self.torrents.update(with: new.map { ($0.hash, $0) })
            })
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    func refresh() -> AnyPublisher<Void, Error> {
        return refreshTorrents()
            .mapError { $0 as Error }
            .ui()
            .handleEvents(receiveCompletion: { [weak self] completion in
                switch completion {
                case let .failure(error):
                    self?.showError(title: "Update Failed", message: error.localizedDescription)
                case .finished:
                    break
                }
            })
            .eraseToAnyPublisher()
    }

    func didSelectItem(at index: Int) {
        let subject = torrents.subject(at: index)
        let viewModel = DelugeTorrentDetailViewModel(
            torrentSubject: subject,
            client: client,
            preferences: preferences,
            refresher: self
        )
        coordinator?.showTorrentDetail(viewModel)
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
            .sink(receiveCompletion: { completion in
                switch completion {
                case let .failure(error):
                    self.showError(title: "Failed to Add Torrent", message: error.localizedDescription)
                case .finished:
                    break
                }
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
        coordinator?.showAlert(alert)
    }
}
