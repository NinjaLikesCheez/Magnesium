//
//  ServerPreferencesTests.swift
//  MagnesiumTests
//
//  Created by James Hurst on 2020-01-09.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
@testable import Magnesium
import Preferences
import XCTest

class ServerPreferencesTests: XCTestCase {
    private let preferences = MockPreferences()
    private let server = Server(name: "Server 1", type: .deluge, data: Data())

    override func setUp() {
        super.setUp()
        preferences.removeServers()
    }

    override func tearDown() {
        super.tearDown()
        preferences.removeServers()
    }

    func testAddServer() {
        preferences.addOrUpdate(server: server)
        XCTAssertEqual(preferences.getServers().count, 1)
        XCTAssertEqual(preferences.getServers()[0], server)
    }

    func testRemoveServer() {
        preferences.addOrUpdate(server: server)
        XCTAssertEqual(preferences.getServers().count, 1)
        preferences.remove(server: server)
        XCTAssertEqual(preferences.getServers().count, 0)
    }

    func testRemoveServers() {
        preferences.addOrUpdate(server: server)
        XCTAssertEqual(preferences.getServers().count, 1)
        preferences.removeServers()
        XCTAssertEqual(preferences.getServers().count, 0)
    }

    func testServerIsNotDuplicated() {
        preferences.addOrUpdate(server: server)
        XCTAssertEqual(preferences.getServers().count, 1)
        preferences.addOrUpdate(server: server)
        XCTAssertEqual(preferences.getServers().count, 1)
    }

    func testServerUpdatedPublisher() {
        let expectation = self.expectation(description: "Value received")
        let observer = preferences.serverUpdatedPublisher(for: server)
            .sink { updated in
                XCTAssertEqual(updated, self.server)
                expectation.fulfill()
            }
        _ = observer

        preferences.addOrUpdate(server: server)
        waitForExpectations(timeout: 1)
    }

    func testServerUpdatedPublisherEmitsUpdatedServer() {
        preferences.addOrUpdate(server: server)

        let expectation = self.expectation(description: "Value received")
        let observer = preferences.serverUpdatedPublisher(for: server)
            .sink { updated in
                XCTAssertEqual(updated?.id, self.server.id)
                XCTAssertEqual(updated?.name, "New Name")
                expectation.fulfill()
            }
        _ = observer

        var server = self.server
        server.name = "New Name"
        preferences.addOrUpdate(server: server)
        waitForExpectations(timeout: 1)
    }

    func testServerUpdatedPublisherNoValueWithSameServer() {
        preferences.addOrUpdate(server: server)

        let expectation = self.expectation(description: "Value received")
        expectation.isInverted = true
        let observer = preferences.serverUpdatedPublisher(for: server)
            .sink { _ in
                expectation.fulfill()
            }
        _ = observer

        preferences.addOrUpdate(server: server)
        waitForExpectations(timeout: 1)
    }

    func testServerUpdatedPublisherNilValueWithDeletedServer() {
        preferences.addOrUpdate(server: server)

        let expectation = self.expectation(description: "Value received")
        let observer = preferences.serverUpdatedPublisher(for: server)
            .sink { updated in
                XCTAssertNil(updated)
                expectation.fulfill()
            }
        _ = observer

        preferences.remove(server: server)
        waitForExpectations(timeout: 1)
    }
}
