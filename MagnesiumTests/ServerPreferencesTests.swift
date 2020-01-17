//
//  ServerPreferencesTests.swift
//  MagnesiumTests
//
//  Created by James Hurst on 2020-01-09.
//  Copyright © 2020 James Hurst. All rights reserved.
//

@testable import Magnesium
import Preferences
import XCTest

class ServerPreferencesTests: XCTestCase {
    private let preferences = UserDefaultsPreferences()
    private let server = Server(name: "Server 1", type: .deluge, data: Data())

    override func setUp() {
        super.setUp()
        preferences.removeServers()
    }

    override func tearDown() {
        super.tearDown()
        preferences.removeServers()
    }

    func testPersistance() {
        preferences.addOrUpdate(server: server)
        XCTAssertEqual(preferences.getServers().count, 1)
        XCTAssertEqual(preferences.getServers()[0].id, server.id)
        let newPreferences = UserDefaultsPreferences()
        XCTAssertEqual(newPreferences.getServers().count, 1)
        XCTAssertEqual(newPreferences.getServers()[0].id, server.id)
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
                XCTAssertEqual(updated.id, self.server.id)
                expectation.fulfill()
            }
        _ = observer

        preferences.addOrUpdate(server: server)

        wait(for: [expectation], timeout: 1)
    }

    func testRemoveServers() {
        preferences.addOrUpdate(server: server)
        XCTAssertEqual(preferences.getServers().count, 1)
        preferences.removeServers()
        XCTAssertEqual(preferences.getServers().count, 0)
        let newPreferences = UserDefaultsPreferences()
        XCTAssertEqual(newPreferences.getServers().count, 0)
    }
}
