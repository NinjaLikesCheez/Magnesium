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
    private(set) var authenticateCallCount = 0
    var authenticateResult = Just(()).setFailureType(to: TransmissionError.self).eraseToAnyPublisher()
    func authenticate() -> AnyPublisher<Void, TransmissionError> {
        authenticateCallCount += 1
        return authenticateResult
    }

    private(set) var getTorrentsCallCount = 0
    var getTorrentsResult = Just([TransmissionTorrent.mock()])
        .setFailureType(to: TransmissionError.self)
        .eraseToAnyPublisher()
    func getTorrents() -> AnyPublisher<[TransmissionTorrent], TransmissionError> {
        getTorrentsCallCount += 1
        return getTorrentsResult
    }

    private(set) var getTorrentFilesCallCount = 0
    private(set) var getTorrentFilesParamID = [Int]()
    var getTorrentFilesResult = Just([
        TransmissionTorrentFile.mock(index: 0, name: "file.rar"),
        TransmissionTorrentFile.mock(index: 1, name: "file.r00"),
        TransmissionTorrentFile.mock(index: 2, name: "file.r01"),
    ]).setFailureType(to: TransmissionError.self).eraseToAnyPublisher()
    func getTorrentFiles(id: Int) -> AnyPublisher<[TransmissionTorrentFile], TransmissionError> {
        getTorrentFilesCallCount += 1
        getTorrentFilesParamID.append(id)
        return getTorrentFilesResult
    }

    private(set) var startCallCount = 0
    private(set) var startParamIDs = [[Int]]()
    var startResult = Just(()).setFailureType(to: TransmissionError.self).eraseToAnyPublisher()
    func start(ids: [Int]) -> AnyPublisher<Void, TransmissionError> {
        startCallCount += 1
        startParamIDs.append(ids)
        return startResult
    }

    private(set) var stopCallCount = 0
    private(set) var stopParamIDs = [[Int]]()
    var stopResult = Just(()).setFailureType(to: TransmissionError.self).eraseToAnyPublisher()
    func stop(ids: [Int]) -> AnyPublisher<Void, TransmissionError> {
        stopCallCount += 1
        stopParamIDs.append(ids)
        return stopResult
    }

    private(set) var removeCallCount = 0
    private(set) var removeParamIDs = [[Int]]()
    private(set) var removeParamRemoveData = [Bool]()
    var removeResult = Just(()).setFailureType(to: TransmissionError.self).eraseToAnyPublisher()
    func remove(ids: [Int], removeData: Bool) -> AnyPublisher<Void, TransmissionError> {
        removeCallCount += 1
        removeParamIDs.append(ids)
        removeParamRemoveData.append(removeData)
        return removeResult
    }

    private(set) var verifyCallCount = 0
    private(set) var verifyParamIDs = [[Int]]()
    var verifyResult = Just(()).setFailureType(to: TransmissionError.self).eraseToAnyPublisher()
    func verify(ids: [Int]) -> AnyPublisher<Void, TransmissionError> {
        verifyCallCount += 1
        verifyParamIDs.append(ids)
        return verifyResult
    }

    private(set) var addURLCallCount = 0
    private(set) var addURLParamURL = [URL]()
    var addURLResult = Just(()).setFailureType(to: TransmissionError.self).eraseToAnyPublisher()
    func add(url: URL) -> AnyPublisher<Void, TransmissionError> {
        addURLCallCount += 1
        addURLParamURL.append(url)
        return addURLResult
    }

    private(set) var addFileURLCallCount = 0
    private(set) var addFileURLParamFileURL = [URL]()
    var addFileURLResult = Just(()).setFailureType(to: TransmissionError.self).eraseToAnyPublisher()
    func add(fileURL: URL) -> AnyPublisher<Void, TransmissionError> {
        addFileURLCallCount += 1
        addFileURLParamFileURL.append(fileURL)
        return addFileURLResult
    }

    private(set) var reannounceCallCount = 0
    private(set) var reannounceParamIDs = [[Int]]()
    var reannounceResult = Just(()).setFailureType(to: TransmissionError.self).eraseToAnyPublisher()
    func reannounce(ids: [Int]) -> AnyPublisher<Void, TransmissionError> {
        reannounceCallCount += 1
        reannounceParamIDs.append(ids)
        return reannounceResult
    }

    private(set) var moveLocationCallCount = 0
    private(set) var moveLocationParamIDs = [[Int]]()
    private(set) var moveLocationParamPath = [String]()
    var moveLocationResult = Just(()).setFailureType(to: TransmissionError.self).eraseToAnyPublisher()
    func moveLocation(ofTorrentIDs ids: [Int], to path: String) -> AnyPublisher<Void, TransmissionError> {
        moveLocationCallCount += 1
        moveLocationParamIDs.append(ids)
        moveLocationParamPath.append(path)
        return moveLocationResult
    }
}
