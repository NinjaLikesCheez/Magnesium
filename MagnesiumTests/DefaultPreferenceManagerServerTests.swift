//
//  DefaultPreferenceManagerServerTests.swift
//  MagnesiumTests
//
//  Created by James Hurst on 2020-01-09.
//  Copyright © 2020 James Hurst. All rights reserved.
//

@testable import Magnesium
import XCTest

class DefaultPreferenceManagerServerTests: XCTestCase {
    private let preferenceManager = DefaultPreferenceManager()

    override func setUp() {
        preferenceManager.removeServers()
    }

    override func tearDown() {
        preferenceManager.removeServers()
    }

    func testPersistance() {
        let server = Server(name: "Server 1", data: Data())
        preferenceManager.addOrUpdate(server: server)
        XCTAssertEqual(preferenceManager.getServers().count, 1)
        XCTAssertEqual(preferenceManager.getServers()[0].id, server.id)
        let newServerManager = DefaultPreferenceManager()
        XCTAssertEqual(newServerManager.getServers().count, 1)
        XCTAssertEqual(newServerManager.getServers()[0].id, server.id)
    }

    func testServerUpdated() {
        let server = Server(name: "Server 1", data: Data())

        let expectation = self.expectation(description: "Value received")
        let observer = preferenceManager.serverUpdatedPublisher(for: server)
            .sink { updated in
                XCTAssertEqual(updated.id, server.id)
                expectation.fulfill()
            }
        _ = observer

        preferenceManager.addOrUpdate(server: server)

        wait(for: [expectation], timeout: 1)
    }

    func testRemoveServers() {
        let server = Server(name: "Server 1", data: Data())
        preferenceManager.addOrUpdate(server: server)
        XCTAssertEqual(preferenceManager.getServers().count, 1)
        preferenceManager.removeServers()
        XCTAssertEqual(preferenceManager.getServers().count, 0)
        let newServerManager = DefaultPreferenceManager()
        XCTAssertEqual(newServerManager.getServers().count, 0)
    }
}
