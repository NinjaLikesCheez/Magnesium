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
    private let serverManager = DefaultServerManager.shared

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
        serverManager.clearCache()
        XCTAssertEqual(serverManager.getServers().count, 1)
    }

    func testSameServerGetsReturned() {
        let server = Server(name: "Server 1", data: Data())
        serverManager.addOrUpdate(server: server)

        let managedServer = serverManager.getServers()[0]
        XCTAssertTrue(server == managedServer)

        let expectation = self.expectation(description: "Value received")
        let observer = server.name.dropFirst().sink { _ in
            expectation.fulfill()
        }
        _ = observer

        managedServer.name.value = "New Name"

        wait(for: [expectation], timeout: 1)
    }

    func testReset() {
        let server = Server(name: "Server 1", data: Data())
        serverManager.addOrUpdate(server: server)
        XCTAssertEqual(serverManager.getServers().count, 1)
        serverManager.reset()
        XCTAssertEqual(serverManager.getServers().count, 0)
        serverManager.clearCache()
        XCTAssertEqual(serverManager.getServers().count, 0)
    }
}
