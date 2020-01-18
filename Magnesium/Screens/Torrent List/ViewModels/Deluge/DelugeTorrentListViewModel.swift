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
    private var observers = [AnyCancellable]()
    private let torrents = TorrentSubjectMapManager<String, DelugeTorrent>()
    private var autoUpdateTimer: Timer?
    private(set) weak var coordinator: TorrentListCoordinator?
    let items: AnyPublisher<[AnyTorrentListItemViewModel], Never>

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

    func refreshTorrents() -> AnyPublisher<Never, DelugeError> {
        return client.fetchTorrents()
            .handleEvents(receiveOutput: { new in
                self.torrents.update(with: new.map { ($0.hash, $0) })
            })
            .ignoreOutput()
            .eraseToAnyPublisher()
    }

    func refresh() -> AnyPublisher<Never, Error> {
        return refreshTorrents()
            .mapError { $0 as Error }
            .ui()
            .handleEvents(receiveCompletion: { [weak self] completion in
                switch completion {
                case let .failure(error):
                    self?.displayError(error, title: "Update Failed")
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

    private func displayError(_ error: Error, title: String) {
        var alert = Alert(
            title: title,
            message: error.localizedDescription,
            style: .alert
        )
        alert.actions.append(AlertAction(title: "OK", style: .default, handler: nil))
        coordinator?.showAlert(alert)
    }
}
