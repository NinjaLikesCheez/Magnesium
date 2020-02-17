//
//  DelugeTorrentDetailViewModelImplementationTests.swift
//  MagnesiumTests
//
//  Created by James Hurst on 2020-02-17.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
@testable import Magnesium
import XCTest

class DelugeTorrentDetailViewModelImplementationTests: XCTestCase {
    private var client: MockDelugeClient!
    private var refresher: MockDelugeRefresher!
    private var implementation: DelugeTorrentDetailViewModelImplementation!
    private var observers = [AnyCancellable]()

    override func setUp() {
        super.setUp()
        client = MockDelugeClient()
        refresher = MockDelugeRefresher()
        implementation = DelugeTorrentDetailViewModelImplementation(client: client, refresher: refresher)
    }

    func test_refresh_shouldCallRefresher() {
        implementation.refresh().sink(receiveCompletion: { _ in }, receiveValue: { _ in }).store(in: &observers)
        XCTAssertEqual(refresher.refreshDelugeCallCount, 1)
    }

    func test_pause_shouldPause() {
        implementation.pause(.mock())
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &observers)
        XCTAssertEqual(client.pauseCallCount, 1)
    }

    func test_resume_shouldResume() {
        implementation.resume(.mock())
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &observers)
        XCTAssertEqual(client.resumeCallCount, 1)
    }

    func test_remove_withKeepData_shouldRemove() {
        implementation.remove(.mock(), removeData: false)
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &observers)
        XCTAssertEqual(client.removeCallCount, 1)
        XCTAssertEqual(client.removeParamRemoveData, [false])
    }

    func test_remove_withRemoveData_shouldRemove() {
        implementation.remove(.mock(), removeData: true)
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &observers)
        XCTAssertEqual(client.removeCallCount, 1)
        XCTAssertEqual(client.removeParamRemoveData, [true])
    }

    func test_verify_shouldRecheck() {
        implementation.verify(.mock())
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &observers)
        XCTAssertEqual(client.recheckCallCount, 1)
    }

    func test_setLabel_shouldSetLabels() {
        implementation.setLabel(.mock(), for: .mock())
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &observers)
        XCTAssertEqual(client.setLabelCallCount, 1)
    }

    func test_updateTrackers_shouldReannounce() {
        implementation.updateTrackers(for: .mock())
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &observers)
        XCTAssertEqual(client.reannounceCallCount, 1)
    }

    func test_moveDownloadFolder_shouldMoveStorage() {
        implementation.moveDownloadFolder(for: .mock(), to: "/new")
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &observers)
        XCTAssertEqual(client.moveStorageCallCount, 1)
        XCTAssertEqual(client.moveStorageParamPath, ["/new"])
    }
}
