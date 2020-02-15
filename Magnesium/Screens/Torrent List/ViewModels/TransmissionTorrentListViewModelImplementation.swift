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
        for torrent: CurrentValueSubject<TransmissionTorrent, Never>,
        labels: CurrentValueSubject<[NeverLabel], Never>
    ) -> AnyTorrentDetailViewModel {
        let implementation = TransmissionTorrentDetailViewModelImplementation(client: client, refresher: self)
        let viewModel = StandardTorrentDetailViewModel(
            implementation: implementation,
            torrent: torrent,
            labels: labels,
            preferences: preferences
        )
        return AnyEmitterViewModel(viewModel)
    }

    func addLink(_ url: String) -> AnyPublisher<(String, String), Never> {
        guard let url = URL(string: url) else {
            return Just((L10n.torrentLinkValidationError, L10n.torrentLinkValidationErrorDescription))
                .eraseToAnyPublisher()
        }

        return client.add(url: url)
            .ignoreOutput()
            .map { _ in ("", "") }
            .catch { error -> AnyPublisher<(String, String), Never> in
                return Just((L10n.addTorrentError, error.localizedDescription)).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    func pause(_ torrents: [TransmissionTorrent]) -> AnyPublisher<Void, Error> {
        return client.stop(ids: torrents.map(\.id)).mapError { $0 as Error }.eraseToAnyPublisher()
    }

    func resume(_ torrents: [TransmissionTorrent]) -> AnyPublisher<Void, Error> {
        return client.start(ids: torrents.map(\.id)).mapError { $0 as Error }.eraseToAnyPublisher()
    }

    func remove(_ torrents: [TransmissionTorrent], removeData: Bool) -> AnyPublisher<Void, Error> {
        return client.remove(ids: torrents.map(\.id), removeData: removeData)
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }

    func verify(_ torrents: [TransmissionTorrent]) -> AnyPublisher<Void, Error> {
        return client.verify(ids: torrents.map(\.id)).mapError { $0 as Error }.eraseToAnyPublisher()
    }

    func setLabel(_ label: NeverLabel, for torrents: [TransmissionTorrent]) -> AnyPublisher<Void, Error> {
        return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    }

    func updateTrackers(for torrents: [TransmissionTorrent]) -> AnyPublisher<Void, Error> {
        return client.reannounce(ids: torrents.map(\.id)).mapError { $0 as Error }.eraseToAnyPublisher()
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
