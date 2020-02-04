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
import ViewModel

// swiftlint:disable:next line_length
final class TransmissionTorrentListViewModelImplementation: StandardTorrentListViewModelImplementation, TransmissionRefreshable {
    typealias Torrent = TransmissionTorrent

    private let client: TransmissionClient
    private let preferences: Preferences
    private let torrentsUpdatedSubject = PassthroughSubject<[Torrent], Never>()
    private var observers = [AnyCancellable]()

    var torrentsUpdated: AnyPublisher<[Torrent], Never> {
        return torrentsUpdatedSubject.eraseToAnyPublisher()
    }

    init(client: TransmissionClient, preferences: Preferences) {
        self.client = client
        self.preferences = preferences
    }

    func refresh() -> AnyPublisher<[Torrent], Error> {
        return client.getTorrents().mapError { $0 as Error }.eraseToAnyPublisher()
    }

    func detailViewModel(for subject: CurrentValueSubject<Torrent, Never>) -> AnyTorrentDetailViewModel {
        let viewModel = TransmissionTorrentDetailViewModel(
            subject: subject,
            client: client,
            preferences: preferences,
            refresher: self
        )
        return AnyEmitterViewModel(viewModel)
    }

    func addLink(_ url: String) -> AnyPublisher<(String, String), Never> {
        guard let url = URL(string: url) else {
            return Just(("Unable to Add Link", "That link doesn't appear to be valid.")).eraseToAnyPublisher()
        }

        return client.add(url: url)
            .ignoreOutput()
            .map { _ in ("", "") }
            .catch { error -> AnyPublisher<(String, String), Never> in
                return Just(("Failed to Add Torrent", error.localizedDescription)).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    func refreshTransmission() -> AnyPublisher<Void, TransmissionError> {
        return client.getTorrents()
            .handleEvents(receiveOutput: { [weak self] torrents in
                self?.torrentsUpdatedSubject.send(torrents)
            })
            .map { _ in () }
            .eraseToAnyPublisher()
    }
}
