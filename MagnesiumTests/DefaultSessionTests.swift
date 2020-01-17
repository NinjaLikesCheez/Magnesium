//
//  DefaultSessionTests.swift
//  MagnesiumTests
//
//  Created by James Hurst on 2020-01-17.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
@testable import Magnesium
import Preferences
import XCTest

class DefaultSessionTests: XCTestCase {
    private let preferences: Preferences = MockPreferences()
    lazy var session: Session = DefaultSession(preferences: preferences)

    func testServerPublisherHasInitialValue() {
        let expectation = self.expectation(description: "Value received")
        let observer = session.serverPublisher
            .sink { _ in
                expectation.fulfill()
            }
        _ = observer
        waitForExpectations(timeout: 1)
    }

    func testServerPublisherEmitsOnAddFirstServer() {
        let server = Server(name: "Server", type: .deluge, data: Data())

        let expectation = self.expectation(description: "Value received")
        let observer = session.serverPublisher
            .dropFirst()
            .sink { new in
                XCTAssertEqual(new, server)
                expectation.fulfill()
            }
        _ = observer

        preferences.addOrUpdate(server: server)
        XCTAssertEqual(session.server, server)
        waitForExpectations(timeout: 1)
    }

    func testServerPublisherEmitsOnUpdateServer() {
        var server = Server(name: "Server", type: .deluge, data: Data())
        preferences.addOrUpdate(server: server)

        let expectation = self.expectation(description: "Value received")
        let observer = session.serverPublisher
            .dropFirst()
            .sink { new in
                XCTAssertEqual(new?.id, server.id)
                XCTAssertEqual(new?.name, "New Name")
                expectation.fulfill()
            }
        _ = observer

        server.name = "New Name"
        preferences.addOrUpdate(server: server)
        XCTAssertEqual(session.server, server)
        waitForExpectations(timeout: 1)
    }

    func testServerPublisherEmitsNextServerOnDelete() {
        let firstServer = Server(name: "Server 1", type: .deluge, data: Data())
        let secondServer = Server(name: "Server 2", type: .deluge, data: Data())
        preferences.addOrUpdate(server: firstServer)
        preferences.addOrUpdate(server: secondServer)

        let expectation = self.expectation(description: "Value received")
        let observer = session.serverPublisher
            .dropFirst()
            .sink { new in
                XCTAssertEqual(new, secondServer)
                expectation.fulfill()
            }
        _ = observer

        XCTAssertEqual(session.server, firstServer)
        preferences.remove(server: firstServer)
        XCTAssertEqual(session.server, secondServer)
        waitForExpectations(timeout: 1)
    }

    func testServerPublisherDoesNotEmitOnPreferenceChange() throws {
        let firstServer = Server(name: "Server 1", type: .deluge, data: Data())
        let secondServer = Server(name: "Server 2", type: .deluge, data: Data())
        preferences.addOrUpdate(server: firstServer)
        preferences.addOrUpdate(server: secondServer)

        let expectation = self.expectation(description: "Value received")
        expectation.isInverted = true
        let observer = session.serverPublisher
            .dropFirst()
            .sink { _ in
                expectation.fulfill()
            }
        _ = observer

        XCTAssertEqual(session.server, firstServer)
        try preferences.set(secondServer.id, for: PreferenceKeys.selectedServerID)
        XCTAssertEqual(session.server, firstServer)
        waitForExpectations(timeout: 1)
    }

    func testServerPublisherEmitsOnServerChange() throws {
        let firstServer = Server(name: "Server 1", type: .deluge, data: Data())
        let secondServer = Server(name: "Server 2", type: .deluge, data: Data())
        preferences.addOrUpdate(server: firstServer)
        preferences.addOrUpdate(server: secondServer)

        let expectation = self.expectation(description: "Value received")
        let observer = session.serverPublisher
            .dropFirst()
            .sink { new in
                XCTAssertEqual(new, secondServer)
                expectation.fulfill()
            }
        _ = observer

        XCTAssertEqual(session.server, firstServer)
        session.setServer(secondServer)
        XCTAssertEqual(session.server, secondServer)
        waitForExpectations(timeout: 1)
    }
}
