//
//  TransmissionTorrentListViewModel.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-14.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import Foundation
import Preferences

final class TransmissionTorrentListViewModel: TorrentListViewModel {
    private let client: TransmissionClient
    private let preferences: Preferences
    private let torrents = TorrentSubjectMapManager<Int, TransmissionTorrent>()
    private var observers = [AnyCancellable]()
    private var autoUpdateTimer: Timer?
    private(set) weak var coordinator: TorrentListCoordinator?
    let items: AnyPublisher<[AnyTorrentListItemViewModel], Never>

    init(coordinator: TorrentListCoordinator, client: TransmissionClient, preferences: Preferences) {
        self.coordinator = coordinator
        self.client = client
        self.preferences = preferences

        items = torrents.sorted
            .map { $0.map { TransmissionTorrentListItemViewModel(torrentSubject: $0).eraseToAny() } }
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
        refresh()
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &observers)
    }

    func refreshTorrents() -> AnyPublisher<Never, TransmissionClientError> {
        return client.getTorrents()
            .handleEvents(receiveOutput: { new in
                self.torrents.update(with: new.map { ($0.id, $0) })
            })
            .ignoreOutput()
            .eraseToAnyPublisher()
    }

    func refresh() -> AnyPublisher<Never, Error> {
        // TODO: display error
        return refreshTorrents()
            .mapError { $0 as Error }
            .ui()
            .eraseToAnyPublisher()
    }

    func didSelectItem(at index: Int) {
        // TODO:
    }
}
