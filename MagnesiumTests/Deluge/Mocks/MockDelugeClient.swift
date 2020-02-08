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
        var authenticate = 0
        var currentState = 0
        var torrentFiles = 0
        var pause = 0
        var resume = 0
        var remove = [Bool]()
        var recheck = 0
        var addURL = 0
        var addMagnetURL = 0
        var setLabel = 0

        mutating func reset() {
            self = Requests()
        }
    }

    struct Errors {
        var authenticate = false
        var currentState = false
        var torrentFiles = false
        var pause = false
        var resume = false
        var removeKeepData = false
        var removeWithData = false
        var recheck = false
        var addURL = false
        var setLabel = false
    }

    var requests = Requests()
    var errors = Errors()
    var torrents = [DelugeTorrent.mock()]
    var labels = [DelugeLabel.mock()]

    func authenticate() -> AnyPublisher<Void, DelugeError> {
        requests.authenticate += 1
        guard !errors.authenticate else {
            return Fail(error: DelugeError.unauthenticated).eraseToAnyPublisher()
        }

        return Just(()).setFailureType(to: DelugeError.self).eraseToAnyPublisher()
    }

    func getCurrentState() -> AnyPublisher<([DelugeTorrent], [DelugeLabel]), DelugeError> {
        requests.currentState += 1
        guard !errors.currentState else {
            return Fail(error: DelugeError.unauthenticated).eraseToAnyPublisher()
        }

        return Just((torrents, labels))
            .setFailureType(to: DelugeError.self)
            .eraseToAnyPublisher()
    }

    func getTorrentFiles(hash: String) -> AnyPublisher<[DelugeTorrentFile], DelugeError> {
        requests.torrentFiles += 1
        guard !errors.torrentFiles else {
            return Fail(error: .unauthenticated).eraseToAnyPublisher()
        }

        return Just([
            DelugeTorrentFile.mock(index: 0, name: "file.rar"),
            DelugeTorrentFile.mock(index: 1, name: "file.r00"),
            DelugeTorrentFile.mock(index: 2, name: "file.r01"),
        ]).setFailureType(to: DelugeError.self).eraseToAnyPublisher()
    }

    func pause(hashes: [String]) -> AnyPublisher<Void, DelugeError> {
        requests.pause += 1
        guard !errors.pause else {
            return Fail(error: .unauthenticated).eraseToAnyPublisher()
        }

        return Just(()).setFailureType(to: DelugeError.self).eraseToAnyPublisher()
    }

    func resume(hashes: [String]) -> AnyPublisher<Void, DelugeError> {
        requests.resume += 1
        guard !errors.resume else {
            return Fail(error: .unauthenticated).eraseToAnyPublisher()
        }

        return Just(()).setFailureType(to: DelugeError.self).eraseToAnyPublisher()
    }

    func remove(hashes: [String], removeData: Bool) -> AnyPublisher<Void, DelugeError> {
        requests.remove.append(removeData)
        guard !(removeData && errors.removeWithData), !(!removeData && errors.removeKeepData) else {
            return Fail(error: .unauthenticated).eraseToAnyPublisher()
        }

        return Just(()).setFailureType(to: DelugeError.self).eraseToAnyPublisher()
    }

    func recheck(hashes: [String]) -> AnyPublisher<Void, DelugeError> {
        requests.recheck += 1
        guard !errors.recheck else {
            return Fail(error: .unauthenticated).eraseToAnyPublisher()
        }

        return Just(()).setFailureType(to: DelugeError.self).eraseToAnyPublisher()
    }

    func add(url: URL) -> AnyPublisher<Void, DelugeError> {
        requests.addURL += 1
        guard !errors.addURL else {
            return Fail(error: .unauthenticated).eraseToAnyPublisher()
        }

        return Just(()).setFailureType(to: DelugeError.self).eraseToAnyPublisher()
    }

    func add(magnetURL: URL) -> AnyPublisher<Void, DelugeError> {
        requests.addMagnetURL += 1
        return Just(()).setFailureType(to: DelugeError.self).eraseToAnyPublisher()
    }

    func add(fileURL: URL) -> AnyPublisher<Void, DelugeError> {
        return Just(()).setFailureType(to: DelugeError.self).eraseToAnyPublisher()
    }

    func setLabel(_ label: String, forTorrentHash hash: String) -> AnyPublisher<Void, DelugeError> {
        requests.setLabel += 1
        guard !errors.setLabel else {
            return Fail(error: .unauthenticated).eraseToAnyPublisher()
        }

        return Just(()).setFailureType(to: DelugeError.self).eraseToAnyPublisher()
    }
}
