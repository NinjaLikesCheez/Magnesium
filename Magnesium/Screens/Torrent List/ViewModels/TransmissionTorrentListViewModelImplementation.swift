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
    private let client: TransmissionClient
    private let preferences: Preferences
    private let updatedSubject = PassthroughSubject<[TransmissionTorrent], Never>()

    var updated: AnyPublisher<([TransmissionTorrent], [NeverLabel]), Never> {
        return updatedSubject.map { ($0, []) }.eraseToAnyPublisher()
    }

    init(client: TransmissionClient, preferences: Preferences) {
        self.client = client
        self.preferences = preferences
    }

    func refresh() -> AnyPublisher<([TransmissionTorrent], [NeverLabel]), Error> {
        return client.getTorrents()
            .map { ($0, []) }
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }

    func detailViewModel(
        for subject: CurrentValueSubject<TransmissionTorrent, Never>,
        labels: CurrentValueSubject<[NeverLabel], Never>
    ) -> AnyTorrentDetailViewModel {
        let implementation = TransmissionTorrentDetailViewModelImplementation(client: client, refresher: self)
        let viewModel = StandardTorrentDetailViewModel(
            implementation: implementation,
            torrent: subject,
            labels: labels,
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

    func pause(_ torrent: TransmissionTorrent) -> AnyPublisher<Void, Error> {
        return client.stop(ids: [torrent.id]).mapError { $0 as Error }.eraseToAnyPublisher()
    }

    func resume(_ torrent: TransmissionTorrent) -> AnyPublisher<Void, Error> {
        return client.start(ids: [torrent.id]).mapError { $0 as Error }.eraseToAnyPublisher()
    }

    func remove(_ torrent: TransmissionTorrent, removeData: Bool) -> AnyPublisher<Void, Error> {
        return client.remove(ids: [torrent.id], removeData: removeData)
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }

    func recheck(_ torrent: TransmissionTorrent) -> AnyPublisher<Void, Error> {
        return client.verify(ids: [torrent.id]).mapError { $0 as Error }.eraseToAnyPublisher()
    }

    func setLabel(_ label: NeverLabel, for torrent: TransmissionTorrent) -> AnyPublisher<Void, Error> {
        return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    }

    func refreshTransmission() -> AnyPublisher<Void, TransmissionError> {
        return client.getTorrents()
            .handleEvents(receiveOutput: { [weak self] torrents in
                self?.updatedSubject.send(torrents)
            })
            .map { _ in () }
            .eraseToAnyPublisher()
    }
}
