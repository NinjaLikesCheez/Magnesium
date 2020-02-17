//
//  TransmissionTorrentDetailViewModelImplementationTests.swift
//  MagnesiumTests
//
//  Created by James Hurst on 2020-02-17.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
@testable import Magnesium
import XCTest

class TransmissionTorrentDetailViewModelImplementationTests: XCTestCase {
    private var client: MockTransmissionClient!
    private var refresher: MockTransmissionRefresher!
    private var implementation: TransmissionTorrentDetailViewModelImplementation!
    private var observers = [AnyCancellable]()

    override func setUp() {
        super.setUp()
        client = MockTransmissionClient()
        refresher = MockTransmissionRefresher()
        implementation = TransmissionTorrentDetailViewModelImplementation(client: client, refresher: refresher)
    }

    func test_refresh_shouldCallRefresher() {
        implementation.refresh().sink(receiveCompletion: { _ in }, receiveValue: { _ in }).store(in: &observers)
        XCTAssertEqual(refresher.refreshTransmissionCallCount, 1)
    }

    func test_pause_shouldStop() {
        implementation.pause(.mock())
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &observers)
        XCTAssertEqual(client.stopCallCount, 1)
    }

    func test_resume_shouldStart() {
        implementation.resume(.mock())
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &observers)
        XCTAssertEqual(client.startCallCount, 1)
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

    func test_verify_shouldVerify() {
        implementation.verify(.mock())
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &observers)
        XCTAssertEqual(client.verifyCallCount, 1)
    }

    func test_updateTrackers_shouldReannounce() {
        implementation.updateTrackers(for: .mock())
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &observers)
        XCTAssertEqual(client.reannounceCallCount, 1)
    }

    func test_moveDownloadFolder_shouldMoveLocation() {
        implementation.moveDownloadFolder(for: .mock(), to: "/new")
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &observers)
        XCTAssertEqual(client.moveLocationCallCount, 1)
        XCTAssertEqual(client.moveLocationParamPath, ["/new"])
    }
}
