//
//  ServerPreferencesTests.swift
//  MagnesiumTests
//
//  Created by James Hurst on 2020-01-09.
//  Copyright © 2020 James Hurst. All rights reserved.
//

@testable import Magnesium
import Navigator
import Preferences
import XCTest

class ServerPreferencesTests: XCTestCase {
    private let preferences = UserDefaultsPreferences()

    override func setUp() {
        super.setUp()
        preferences.removeServers()
    }

    override func tearDown() {
        super.tearDown()
        preferences.removeServers()
    }

    func testPersistance() {
        let server = Server(name: "Server 1", data: Data())
        preferences.addOrUpdate(server: server)
        XCTAssertEqual(preferences.getServers().count, 1)
        XCTAssertEqual(preferences.getServers()[0].id, server.id)
        let newPreferences = UserDefaultsPreferences()
        XCTAssertEqual(newPreferences.getServers().count, 1)
        XCTAssertEqual(newPreferences.getServers()[0].id, server.id)
    }

    func testServerIsNotDuplicated() {
        let server = Server(name: "Server 1", data: Data())
        preferences.addOrUpdate(server: server)
        XCTAssertEqual(preferences.getServers().count, 1)
        preferences.addOrUpdate(server: server)
        XCTAssertEqual(preferences.getServers().count, 1)
    }

    func testServerUpdatedPublisher() {
        let server = Server(name: "Server 1", data: Data())

        let expectation = self.expectation(description: "Value received")
        let observer = preferences.serverUpdatedPublisher(for: server)
            .sink { updated in
                XCTAssertEqual(updated.id, server.id)
                expectation.fulfill()
            }
        _ = observer

        preferences.addOrUpdate(server: server)

        wait(for: [expectation], timeout: 1)
    }

    func testRemoveServers() {
        let server = Server(name: "Server 1", data: Data())
        preferences.addOrUpdate(server: server)
        XCTAssertEqual(preferences.getServers().count, 1)
        preferences.removeServers()
        XCTAssertEqual(preferences.getServers().count, 0)
        let newPreferences = UserDefaultsPreferences()
        XCTAssertEqual(newPreferences.getServers().count, 0)
    }
}
