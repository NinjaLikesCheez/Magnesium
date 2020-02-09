//
//  DelugeTorrentListViewModelImplementation.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-07.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import Foundation
import Preferences
import ViewModel

final class DelugeTorrentListViewModelImplementation: StandardTorrentListViewModelImplementation, DelugeRefreshable {
    private let client: DelugeClient
    private let preferences: Preferences
    private let updatedSubject = PassthroughSubject<([DelugeTorrent], [DelugeLabel]), Never>()

    var updated: AnyPublisher<([DelugeTorrent], [DelugeLabel]), Never> {
        return updatedSubject.eraseToAnyPublisher()
    }

    init(client: DelugeClient, preferences: Preferences) {
        self.client = client
        self.preferences = preferences
    }

    func refresh() -> AnyPublisher<([DelugeTorrent], [DelugeLabel]), Error> {
        return client.getCurrentState()
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }

    func detailViewModel(
        for subject: CurrentValueSubject<DelugeTorrent, Never>,
        labels: CurrentValueSubject<[DelugeLabel], Never>
    ) -> AnyTorrentDetailViewModel {
        let implementation = DelugeTorrentDetailViewModelImplementation(client: client, refresher: self)
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

        let publisher: AnyPublisher<Void, DelugeError>

        if url.scheme == "magnet" {
            publisher = client.add(magnetURL: url)
        } else {
            publisher = client.add(url: url)
        }

        return publisher
            .ignoreOutput()
            .map { _ in ("", "") }
            .catch { error -> AnyPublisher<(String, String), Never> in
                return Just(("Failed to Add Torrent", error.localizedDescription)).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    func pause(_ torrent: DelugeTorrent) -> AnyPublisher<Void, Error> {
        return client.pause(hashes: [torrent.hash]).mapError { $0 as Error }.eraseToAnyPublisher()
    }

    func resume(_ torrent: DelugeTorrent) -> AnyPublisher<Void, Error> {
        return client.resume(hashes: [torrent.hash]).mapError { $0 as Error }.eraseToAnyPublisher()
    }

    func remove(_ torrent: DelugeTorrent, removeData: Bool) -> AnyPublisher<Void, Error> {
        return client.remove(hashes: [torrent.hash], removeData: removeData)
            .map { _ in () }
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }

    func setLabel(_ label: DelugeLabel, for torrent: Torrent) -> AnyPublisher<Void, Error> {
        return client.setLabel(label.name, forTorrentHash: torrent.hash).mapError { $0 as Error }.eraseToAnyPublisher()
    }

    func refreshDeluge() -> AnyPublisher<Void, DelugeError> {
        return client.getCurrentState()
            .handleEvents(receiveOutput: { [weak self] in
                self?.updatedSubject.send($0)
            })
            .map { _ in () }
            .eraseToAnyPublisher()
    }
}
