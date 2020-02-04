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
    typealias Torrent = DelugeTorrent

    private let client: DelugeClient
    private let preferences: Preferences
    private let torrentsUpdatedSubject = PassthroughSubject<[DelugeTorrent], Never>()
    private var observers = [AnyCancellable]()

    var torrentsUpdated: AnyPublisher<[DelugeTorrent], Never> {
        return torrentsUpdatedSubject.eraseToAnyPublisher()
    }

    init(client: DelugeClient, preferences: Preferences) {
        self.client = client
        self.preferences = preferences
    }

    func refresh() -> AnyPublisher<[DelugeTorrent], Error> {
        return client.getTorrents().mapError { $0 as Error }.eraseToAnyPublisher()
    }

    func detailViewModel(for subject: CurrentValueSubject<DelugeTorrent, Never>) -> AnyTorrentDetailViewModel {
        let implementation = DelugeTorrentDetailViewModelImplementation(
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

    func refreshDeluge() -> AnyPublisher<Void, DelugeError> {
        return client.getTorrents()
            .handleEvents(receiveOutput: { [weak self] torrents in
                self?.torrentsUpdatedSubject.send(torrents)
            })
            .map { _ in () }
            .eraseToAnyPublisher()
    }
}
