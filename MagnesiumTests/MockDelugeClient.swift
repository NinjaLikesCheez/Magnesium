//
//  MockDelugeClient.swift
//  MagnesiumTests
//
//  Created by James Hurst on 2020-01-21.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import Foundation
@testable import Magnesium

final class MockDelugeClient: DelugeClient {
    struct Requests: Equatable {
        var torrents = 0
        var addURL = 0
        var addMagnetURL = 0

        mutating func reset() {
            self = Requests()
        }
    }

    struct Errors {
        var torrents = false
        var addURL = false
    }

    var requests = Requests()
    var errors = Errors()

    func authenticate() -> AnyPublisher<Never, DelugeError> {
        return Empty(completeImmediately: true).eraseToAnyPublisher()
    }

    func fetchTorrents() -> AnyPublisher<[DelugeTorrent], DelugeError> {
        guard !errors.torrents else {
            return Fail(error: DelugeError.unauthenticated).eraseToAnyPublisher()
        }

        requests.torrents += 1
        return Just([DelugeTorrent.mock()])
            .setFailureType(to: DelugeError.self)
            .eraseToAnyPublisher()
    }

    func fetchLabels() -> AnyPublisher<[String], DelugeError> {
        return Just([]).setFailureType(to: DelugeError.self).eraseToAnyPublisher()
    }

    func fetchTorrentFiles(hash: String) -> AnyPublisher<[DelugeTorrentFile], DelugeError> {
        return Just([]).setFailureType(to: DelugeError.self).eraseToAnyPublisher()
    }

    func pause(hashes: [String]) -> AnyPublisher<Never, DelugeError> {
        return Empty(completeImmediately: true).eraseToAnyPublisher()
    }

    func resume(hashes: [String]) -> AnyPublisher<Never, DelugeError> {
        return Empty(completeImmediately: true).eraseToAnyPublisher()
    }

    func remove(hashes: [String], removeData: Bool) -> AnyPublisher<Never, DelugeError> {
        return Empty(completeImmediately: true).eraseToAnyPublisher()
    }

    func recheck(hashes: [String]) -> AnyPublisher<Never, DelugeError> {
        return Empty(completeImmediately: true).eraseToAnyPublisher()
    }

    func add(url: URL) -> AnyPublisher<Never, DelugeError> {
        guard !errors.addURL else {
            return Fail(error: DelugeError.unauthenticated).eraseToAnyPublisher()
        }

        requests.addURL += 1
        return Empty(completeImmediately: true).eraseToAnyPublisher()
    }

    func add(magnetURL: URL) -> AnyPublisher<Never, DelugeError> {
        requests.addMagnetURL += 1
        return Empty(completeImmediately: true).eraseToAnyPublisher()
    }

    func add(fileURL: URL) -> AnyPublisher<Never, DelugeError> {
        return Empty(completeImmediately: true).eraseToAnyPublisher()
    }
}
