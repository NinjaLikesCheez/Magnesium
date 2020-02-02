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
        var addURL = 0

        mutating func reset() {
            self = Requests()
        }
    }

    struct Errors {
        var authenticate = false
        var torrents = false
        var torrentFiles = false
        var pause = false
        var resume = false
        var removeKeepData = false
        var removeWithData = false
        var recheck = false
        var addURL = false
    }

    var requests = Requests()
    var errors = Errors()
    var torrents = [TransmissionTorrent.mock()]

    func authenticate() -> AnyPublisher<Void, TransmissionError> {
        guard !errors.authenticate else {
            return Fail(error: .unauthenticated).eraseToAnyPublisher()
        }

        requests.authenticate += 1
        return Just(()).setFailureType(to: TransmissionError.self).eraseToAnyPublisher()
    }

    func fetchTorrents() -> AnyPublisher<[TransmissionTorrent], TransmissionError> {
        guard !errors.torrents else {
            return Fail(error: .unauthenticated).eraseToAnyPublisher()
        }

        requests.torrents += 1
        return Just(torrents)
            .setFailureType(to: TransmissionError.self)
            .eraseToAnyPublisher()
    }

    func add(url: URL) -> AnyPublisher<Void, TransmissionError> {
        guard !errors.addURL else {
            return Fail(error: .unauthenticated).eraseToAnyPublisher()
        }

        requests.addURL += 1
        return Just(()).setFailureType(to: TransmissionError.self).eraseToAnyPublisher()
    }

    func add(fileURL: URL) -> AnyPublisher<Void, TransmissionError> {
        return Just(()).setFailureType(to: TransmissionError.self).eraseToAnyPublisher()
    }
}
