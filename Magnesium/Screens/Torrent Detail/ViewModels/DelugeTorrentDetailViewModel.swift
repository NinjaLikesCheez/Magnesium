//
//  DelugeTorrentDetailViewModel.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-07.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import Foundation
import Preferences
import ViewModel

final class DelugeTorrentDetailViewModel: StandardTorrentDetailViewModel<
    DelugeTorrent,
    DelugeTorrentFile
>, StandardTorrentDetailViewModelImplementation {
    private let subject: CurrentValueSubject<DelugeTorrent, Never>
    private let client: DelugeClient
    private let refresher: DelugeRefreshable
    private var observers = [AnyCancellable]()

    init(
        subject: CurrentValueSubject<DelugeTorrent, Never>,
        client: DelugeClient,
        preferences: Preferences,
        refresher: DelugeRefreshable
    ) {
        self.subject = subject
        self.client = client
        self.refresher = refresher
        super.init(subject: subject, preferences: preferences)
        setup(with: self)
    }

    func refresh() -> AnyPublisher<Void, Error> {
        return refresher.refreshDeluge().mapError { $0 as Error }.eraseToAnyPublisher()
    }

    func pause() -> AnyPublisher<Void, Error> {
        return client.pause(hashes: [subject.value.hash]).mapError { $0 as Error }.eraseToAnyPublisher()
    }

    func resume() -> AnyPublisher<Void, Error> {
        return client.resume(hashes: [subject.value.hash]).mapError { $0 as Error }.eraseToAnyPublisher()
    }

    func remove(removeData: Bool) -> AnyPublisher<Void, Error> {
        return client.remove(hashes: [subject.value.hash], removeData: removeData)
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }

    func recheck() -> AnyPublisher<Void, Error> {
        return client.recheck(hashes: [subject.value.hash]).mapError { $0 as Error }.eraseToAnyPublisher()
    }

    func updateFiles() -> AnyPublisher<Void, Error> {
        return client.getTorrentFiles(hash: subject.value.hash)
            .handleEvents(receiveOutput: { [weak self] new in
                self?.files.update(with: new.map { ($0.index, $0) })
            })
            .map { _ in () }
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }
}

extension DelugeTorrent: StandardDetailTorrent {}
extension DelugeTorrentFile: StandardDetailTorrentFile {}
