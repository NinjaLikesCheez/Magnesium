//
//  MockTransmissionClient.swift
//  MagnesiumTests
//
//  Created by James Hurst on 2020-02-01.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import Foundation
@testable import Magnesium

final class MockTransmissionClient: TransmissionClient {
    struct Requests: Equatable {
        var authenticate = 0
        var torrents = 0
        var torrentFiles = 0
        var start = 0
        var stop = 0
        var remove = [Bool]()
        var verify = 0
        var addURL = 0

        mutating func reset() {
            self = Requests()
        }
    }

    struct Errors {
        var authenticate = false
        var torrents = false
        var torrentFiles = false
        var start = false
        var stop = false
        var removeKeepData = false
        var removeWithData = false
        var verify = false
        var addURL = false
    }

    var requests = Requests()
    var errors = Errors()
    var torrents = [TransmissionTorrent.mock()]

    func authenticate() -> AnyPublisher<Void, TransmissionError> {
        requests.authenticate += 1
        guard !errors.authenticate else {
            return Fail(error: .unauthenticated).eraseToAnyPublisher()
        }

        return Just(()).setFailureType(to: TransmissionError.self).eraseToAnyPublisher()
    }

    func getTorrents() -> AnyPublisher<[TransmissionTorrent], TransmissionError> {
        requests.torrents += 1
        guard !errors.torrents else {
            return Fail(error: .unauthenticated).eraseToAnyPublisher()
        }

        return Just(torrents)
            .setFailureType(to: TransmissionError.self)
            .eraseToAnyPublisher()
    }

    func getTorrentFiles(id: Int) -> AnyPublisher<[TransmissionTorrentFile], TransmissionError> {
        requests.torrentFiles += 1
        guard !errors.torrentFiles else {
            return Fail(error: .unauthenticated).eraseToAnyPublisher()
        }

        return Just([
            TransmissionTorrentFile.mock(index: 0, name: "file.rar"),
            TransmissionTorrentFile.mock(index: 1, name: "file.r00"),
            TransmissionTorrentFile.mock(index: 2, name: "file.r01"),
        ]).setFailureType(to: TransmissionError.self).eraseToAnyPublisher()
    }

    func start(ids: [Int]) -> AnyPublisher<Void, TransmissionError> {
        requests.start += 1
        guard !errors.start else {
            return Fail(error: .unauthenticated).eraseToAnyPublisher()
        }

        return Just(()).setFailureType(to: TransmissionError.self).eraseToAnyPublisher()
    }

    func stop(ids: [Int]) -> AnyPublisher<Void, TransmissionError> {
        requests.stop += 1
        guard !errors.stop else {
            return Fail(error: .unauthenticated).eraseToAnyPublisher()
        }

        return Just(()).setFailureType(to: TransmissionError.self).eraseToAnyPublisher()
    }

    func remove(ids: [Int], removeData: Bool) -> AnyPublisher<Void, TransmissionError> {
        requests.remove.append(removeData)
        guard !(removeData && errors.removeWithData), !(!removeData && errors.removeKeepData) else {
            return Fail(error: .unauthenticated).eraseToAnyPublisher()
        }

        return Just(()).setFailureType(to: TransmissionError.self).eraseToAnyPublisher()
    }

    func verify(ids: [Int]) -> AnyPublisher<Void, TransmissionError> {
        requests.verify += 1
        guard !errors.verify else {
            return Fail(error: .unauthenticated).eraseToAnyPublisher()
        }

        return Just(()).setFailureType(to: TransmissionError.self).eraseToAnyPublisher()
    }

    func add(url: URL) -> AnyPublisher<Void, TransmissionError> {
        requests.addURL += 1
        guard !errors.addURL else {
            return Fail(error: .unauthenticated).eraseToAnyPublisher()
        }

        return Just(()).setFailureType(to: TransmissionError.self).eraseToAnyPublisher()
    }

    func add(fileURL: URL) -> AnyPublisher<Void, TransmissionError> {
        return Just(()).setFailureType(to: TransmissionError.self).eraseToAnyPublisher()
    }
}
