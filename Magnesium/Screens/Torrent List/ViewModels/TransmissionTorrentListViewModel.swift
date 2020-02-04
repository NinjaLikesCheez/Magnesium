//
//  TransmissionTorrentListViewModelImplementation.swift
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
    private let torrentsUpdatedSubject = PassthroughSubject<[TransmissionTorrent], Never>()
    private var observers = [AnyCancellable]()

    var torrentsUpdated: AnyPublisher<[TransmissionTorrent], Never> {
        return torrentsUpdatedSubject.eraseToAnyPublisher()
    }

    init(client: TransmissionClient, preferences: Preferences) {
        self.client = client
        self.preferences = preferences
    }

    func refresh() -> AnyPublisher<[TransmissionTorrent], Error> {
        return client.getTorrents().mapError { $0 as Error }.eraseToAnyPublisher()
    }

    func detailViewModel(for subject: CurrentValueSubject<TransmissionTorrent, Never>) -> AnyTorrentDetailViewModel {
        let implementation = TransmissionTorrentDetailViewModelImplementation(
            subject: subject,
            client: client,
            refresher: self
        )
        let viewModel = StandardTorrentDetailViewModel(
            implementation: implementation,
            subject: subject,
            preferences: preferences
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
