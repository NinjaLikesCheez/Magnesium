//
//  TransmissionTorrentDetailViewModelImplementation.swift
//  Magnesium
//
//  Created by James Hurst on 2020-02-02.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine

final class TransmissionTorrentDetailViewModelImplementation: StandardTorrentDetailViewModelImplementation {
    typealias Torrent = TransmissionTorrent
    typealias File = TransmissionTorrentFile

    private let subject: CurrentValueSubject<TransmissionTorrent, Never>
    private let client: TransmissionClient
    private let refresher: TransmissionRefreshable

    init(
        subject: CurrentValueSubject<TransmissionTorrent, Never>,
        client: TransmissionClient,
        refresher: TransmissionRefreshable
    ) {
        self.subject = subject
        self.client = client
        self.refresher = refresher
    }

    func refresh() -> AnyPublisher<Void, Error> {
        return refresher.refreshTransmission().mapError { $0 as Error }.eraseToAnyPublisher()
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

    func updateFiles(_ torrent: TransmissionTorrent) -> AnyPublisher<[TransmissionTorrentFile], Error> {
        return client.getTorrentFiles(id: torrent.id).mapError { $0 as Error }.eraseToAnyPublisher()
    }
}
