//
//  DefaultServerManagerTests.swift
//  MagnesiumTests
//
//  Created by James Hurst on 2020-01-09.
//  Copyright © 2020 James Hurst. All rights reserved.
//

@testable import Magnesium
import XCTest

class DefaultServerManagerTests: XCTestCase {
    private let serverManager = DefaultServerManager()

    override func setUp() {
        serverManager.reset()
    }

    override func tearDown() {
        serverManager.reset()
    }

    func testPersistance() {
        let server = Server(name: "Server 1", data: Data())
        serverManager.addOrUpdate(server: server)
        XCTAssertEqual(serverManager.getServers().count, 1)
        XCTAssertEqual(serverManager.getServers()[0].id, server.id)
        let newServerManager = DefaultServerManager()
        XCTAssertEqual(newServerManager.getServers().count, 1)
        XCTAssertEqual(newServerManager.getServers()[0].id, server.id)
    }

    func testServerUpdated() {
        let server = Server(name: "Server 1", data: Data())

        let expectation = self.expectation(description: "Value received")
        let observer = serverManager.serverUpdated.sink { updated in
            XCTAssertEqual(updated.id, server.id)
            expectation.fulfill()
        }
        _ = observer

        serverManager.addOrUpdate(server: server)

        wait(for: [expectation], timeout: 1)
    }

    func testReset() {
        let server = Server(name: "Server 1", data: Data())
        serverManager.addOrUpdate(server: server)
        XCTAssertEqual(serverManager.getServers().count, 1)
        serverManager.reset()
        XCTAssertEqual(serverManager.getServers().count, 0)
        let newServerManager = DefaultServerManager()
        XCTAssertEqual(newServerManager.getServers().count, 0)
    }
}
