//
//  DelugeTorrentDetailViewModelImplementation.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-07.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import Foundation
import Preferences
import ViewModel

final class DelugeTorrentDetailViewModelImplementation: StandardTorrentDetailViewModelImplementation {
    typealias Torrent = DelugeTorrent
    typealias File = DelugeTorrentFile

    private let subject: CurrentValueSubject<DelugeTorrent, Never>
    private let client: DelugeClient
    private let refresher: DelugeRefreshable
    private var observers = [AnyCancellable]()

    init(
        subject: CurrentValueSubject<DelugeTorrent, Never>,
        client: DelugeClient,
        refresher: DelugeRefreshable
    ) {
        self.subject = subject
        self.client = client
        self.refresher = refresher
    }

    func refresh() -> AnyPublisher<Void, Error> {
        return refresher.refreshDeluge().mapError { $0 as Error }.eraseToAnyPublisher()
    }

    func pause(_ torrent: DelugeTorrent) -> AnyPublisher<Void, Error> {
        return client.pause(hashes: [torrent.hash]).mapError { $0 as Error }.eraseToAnyPublisher()
    }

    func resume(_ torrent: DelugeTorrent) -> AnyPublisher<Void, Error> {
        return client.resume(hashes: [torrent.hash]).mapError { $0 as Error }.eraseToAnyPublisher()
    }

    func remove(_ torrent: DelugeTorrent, removeData: Bool) -> AnyPublisher<Void, Error> {
        return client.remove(hashes: [torrent.hash], removeData: removeData)
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }

    func recheck(_ torrent: DelugeTorrent) -> AnyPublisher<Void, Error> {
        return client.recheck(hashes: [torrent.hash]).mapError { $0 as Error }.eraseToAnyPublisher()
    }

    func updateFiles(_ torrent: DelugeTorrent) -> AnyPublisher<[DelugeTorrentFile], Error> {
        return client.getTorrentFiles(hash: torrent.hash).mapError { $0 as Error }.eraseToAnyPublisher()
    }
}
