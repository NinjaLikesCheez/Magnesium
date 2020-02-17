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
    private(set) var authenticateCallCount = 0
    var authenticateResult = Just(()).setFailureType(to: DelugeError.self).eraseToAnyPublisher()
    func authenticate() -> AnyPublisher<Void, DelugeError> {
        authenticateCallCount += 1
        return authenticateResult
    }

    private(set) var getCurrentStateCallCount = 0
    var getCurrentStateResult = Just(([DelugeTorrent.mock()], [DelugeLabel.mock()]))
        .setFailureType(to: DelugeError.self)
        .eraseToAnyPublisher()
    func getCurrentState() -> AnyPublisher<([DelugeTorrent], [DelugeLabel]), DelugeError> {
        getCurrentStateCallCount += 1
        return getCurrentStateResult
    }

    private(set) var getTorrentFilesCallCount = 0
    private(set) var getTorrentFilesParamHash = [String]()
    var getTorrentFilesResult = Just([
        DelugeTorrentFile.mock(index: 0, name: "file.rar"),
        DelugeTorrentFile.mock(index: 1, name: "file.r00"),
        DelugeTorrentFile.mock(index: 2, name: "file.r01"),
    ]).setFailureType(to: DelugeError.self).eraseToAnyPublisher()
    func getTorrentFiles(hash: String) -> AnyPublisher<[DelugeTorrentFile], DelugeError> {
        getTorrentFilesCallCount += 1
        getTorrentFilesParamHash.append(hash)
        return getTorrentFilesResult
    }

    private(set) var pauseCallCount = 0
    private(set) var pauseParamHashes = [[String]]()
    var pauseResult = Just(()).setFailureType(to: DelugeError.self).eraseToAnyPublisher()
    func pause(hashes: [String]) -> AnyPublisher<Void, DelugeError> {
        pauseCallCount += 1
        pauseParamHashes.append(hashes)
        return pauseResult
    }

    private(set) var resumeCallCount = 0
    private(set) var resumeParamHashes = [[String]]()
    var resumeResult = Just(()).setFailureType(to: DelugeError.self).eraseToAnyPublisher()
    func resume(hashes: [String]) -> AnyPublisher<Void, DelugeError> {
        resumeCallCount += 1
        resumeParamHashes.append(hashes)
        return resumeResult
    }

    private(set) var removeCallCount = 0
    private(set) var removeParamHashes = [[String]]()
    private(set) var removeParamRemoveData = [Bool]()
    var removeResult = Just(()).setFailureType(to: DelugeError.self).eraseToAnyPublisher()
    func remove(hashes: [String], removeData: Bool) -> AnyPublisher<Void, DelugeError> {
        removeCallCount += 1
        removeParamHashes.append(hashes)
        removeParamRemoveData.append(removeData)
        return removeResult
    }

    private(set) var recheckCallCount = 0
    private(set) var recheckParamHashes = [[String]]()
    var recheckResult = Just(()).setFailureType(to: DelugeError.self).eraseToAnyPublisher()
    func recheck(hashes: [String]) -> AnyPublisher<Void, DelugeError> {
        recheckCallCount += 1
        recheckParamHashes.append(hashes)
        return recheckResult
    }

    private(set) var addURLCallCount = 0
    private(set) var addURLParamURL = [URL]()
    var addURLResult = Just(()).setFailureType(to: DelugeError.self).eraseToAnyPublisher()
    func add(url: URL) -> AnyPublisher<Void, DelugeError> {
        addURLCallCount += 1
        addURLParamURL.append(url)
        return addURLResult
    }

    private(set) var addMagnetURLCallCount = 0
    private(set) var addMagnetURLParamMagnetURL = [URL]()
    var addMagnetURLResult = Just(()).setFailureType(to: DelugeError.self).eraseToAnyPublisher()
    func add(magnetURL: URL) -> AnyPublisher<Void, DelugeError> {
        addMagnetURLCallCount += 1
        addMagnetURLParamMagnetURL.append(magnetURL)
        return addMagnetURLResult
    }

    private(set) var addFileURLCallCount = 0
    private(set) var addFileURLParamFileURL = [URL]()
    var addFileURLResult = Just(()).setFailureType(to: DelugeError.self).eraseToAnyPublisher()
    func add(fileURL: URL) -> AnyPublisher<Void, DelugeError> {
        addFileURLCallCount += 1
        addFileURLParamFileURL.append(fileURL)
        return addFileURLResult
    }

    private(set) var setLabelCallCount = 0
    private(set) var setLabelParamLabel = [String]()
    private(set) var setLabelParamHash = [String]()
    var setLabelResult = Just(()).setFailureType(to: DelugeError.self).eraseToAnyPublisher()
    func setLabel(_ label: String, forTorrentHash hash: String) -> AnyPublisher<Void, DelugeError> {
        setLabelCallCount += 1
        setLabelParamLabel.append(label)
        setLabelParamHash.append(hash)
        return setLabelResult
    }

    private(set) var reannounceCallCount = 0
    private(set) var reannounceParamHashes = [[String]]()
    var reannounceResult = Just(()).setFailureType(to: DelugeError.self).eraseToAnyPublisher()
    func reannounce(hashes: [String]) -> AnyPublisher<Void, DelugeError> {
        reannounceCallCount += 1
        reannounceParamHashes.append(hashes)
        return reannounceResult
    }

    private(set) var moveStorageCallCount = 0
    private(set) var moveStorageParamHashes = [[String]]()
    private(set) var moveStorageParamPath = [String]()
    var moveStorageResult = Just(()).setFailureType(to: DelugeError.self).eraseToAnyPublisher()
    func moveStorage(forTorrentHashes hashes: [String], to path: String) -> AnyPublisher<Void, DelugeError> {
        moveStorageCallCount += 1
        moveStorageParamHashes.append(hashes)
        moveStorageParamPath.append(path)
        return moveStorageResult
    }
}
