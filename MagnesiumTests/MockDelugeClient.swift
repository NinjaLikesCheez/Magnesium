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
        var torrentFiles = 0
        var pause = 0
        var resume = 0
        var remove = [Bool]()
        var recheck = 0
        var addURL = 0
        var addMagnetURL = 0

        mutating func reset() {
            self = Requests()
        }
    }

    struct Errors {
        var torrents = false
        var torrentFiles = false
        var addURL = false
    }

    var requests = Requests()
    var errors = Errors()

    func authenticate() -> AnyPublisher<Void, DelugeError> {
        return Just(()).setFailureType(to: DelugeError.self).eraseToAnyPublisher()
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
        guard !errors.torrentFiles else {
            return Fail(error: DelugeError.unauthenticated).eraseToAnyPublisher()
        }

        requests.torrentFiles += 1
        return Just([
            DelugeTorrentFile.mock(name: "file.rar"),
            DelugeTorrentFile.mock(name: "file.r00"),
            DelugeTorrentFile.mock(name: "file.r01"),
        ]).setFailureType(to: DelugeError.self).eraseToAnyPublisher()
    }

    func pause(hashes: [String]) -> AnyPublisher<Void, DelugeError> {
        requests.pause += 1
        return Just(()).setFailureType(to: DelugeError.self).eraseToAnyPublisher()
    }

    func resume(hashes: [String]) -> AnyPublisher<Void, DelugeError> {
        requests.resume += 1
        return Just(()).setFailureType(to: DelugeError.self).eraseToAnyPublisher()
    }

    func remove(hashes: [String], removeData: Bool) -> AnyPublisher<Void, DelugeError> {
        requests.remove.append(removeData)
        return Just(()).setFailureType(to: DelugeError.self).eraseToAnyPublisher()
    }

    func recheck(hashes: [String]) -> AnyPublisher<Void, DelugeError> {
        requests.recheck += 1
        return Just(()).setFailureType(to: DelugeError.self).eraseToAnyPublisher()
    }

    func add(url: URL) -> AnyPublisher<Void, DelugeError> {
        guard !errors.addURL else {
            return Fail(error: DelugeError.unauthenticated).eraseToAnyPublisher()
        }

        requests.addURL += 1
        return Just(()).setFailureType(to: DelugeError.self).eraseToAnyPublisher()
    }

    func add(magnetURL: URL) -> AnyPublisher<Void, DelugeError> {
        requests.addMagnetURL += 1
        return Just(()).setFailureType(to: DelugeError.self).eraseToAnyPublisher()
    }

    func add(fileURL: URL) -> AnyPublisher<Void, DelugeError> {
        return Just(()).setFailureType(to: DelugeError.self).eraseToAnyPublisher()
    }
}
