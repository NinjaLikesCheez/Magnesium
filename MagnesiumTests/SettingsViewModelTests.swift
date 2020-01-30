//
//  SettingsViewModelTests.swift
//  MagnesiumTests
//
//  Created by James Hurst on 2020-01-29.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
@testable import Magnesium
import XCTest

class SettingsViewModelTests: XCTestCase {
    private let preferences = MockPreferences()
    private var observers = [AnyCancellable]()
    private lazy var session = DefaultSession(preferences: preferences)
    private lazy var viewModel = SettingsViewModel(session: session, preferences: preferences)

    func testSectionsUpdatedOnServersChanged() {
        let expectation = self.expectation(description: "Value received")
        viewModel.state.sections.dropFirst().first().sink { _ in
            expectation.fulfill()
        }.store(in: &observers)
        preferences.addOrUpdate(server: Server(name: "", type: .deluge, data: Data(), keychainData: nil))
        waitForExpectations(timeout: 0)
    }

    func testSectionsUpdatedOnCurrentServerChanged() {
        let expectation = self.expectation(description: "Value received")
        viewModel.state.sections.dropFirst().first().sink { _ in
            expectation.fulfill()
        }.store(in: &observers)
        session.setServer(Server(name: "", type: .deluge, data: Data(), keychainData: nil))
        waitForExpectations(timeout: 0)
    }

    func testCloseEmitsCompleteEvent() {
        let expectation = self.expectation(description: "Value received")
        viewModel.events.first().sink {
            guard case .complete = $0 else {
                XCTFail("Unexpected event")
                return
            }
            expectation.fulfill()
        }.store(in: &observers)
        viewModel.handle(.close)
        waitForExpectations(timeout: 0)
    }

    func testChangeServerAlert() {
        let server1 = Server(name: "Server 1", type: .deluge, data: Data(), keychainData: nil)
        let server2 = Server(name: "Server 2", type: .deluge, data: Data(), keychainData: nil)
        preferences.addOrUpdate(server: server1)
        preferences.addOrUpdate(server: server2)

        var alert: Alert?
        viewModel.events.first().sink {
            guard case let .alert(inner, source: _) = $0 else {
                XCTFail("Unexpected event")
                return
            }
            alert = inner
        }.store(in: &observers)

        viewModel.handle(.changeServer(source: .view(UIView(), rect: .zero)))
        let expected = ["Server 1", "Server 2", "Cancel"]
        XCTAssertEqual(alert?.actions.map { $0.title ?? "" }, expected)
    }

    func testChangeServerUpdatesSession() {
        let server1 = Server(name: "Server 1", type: .deluge, data: Data(), keychainData: nil)
        let server2 = Server(name: "Server 2", type: .deluge, data: Data(), keychainData: nil)
        preferences.addOrUpdate(server: server1)
        preferences.addOrUpdate(server: server2)
        session.setServer(server1)

        var alert: Alert?
        viewModel.events.first().sink {
            guard case let .alert(inner, source: _) = $0 else {
                XCTFail("Unexpected event")
                return
            }
            alert = inner
        }.store(in: &observers)
        viewModel.handle(.changeServer(source: .view(UIView(), rect: .zero)))
        let changeServer = alert!.actions[1].handler!

        let previousID = session.server!.id
        changeServer()
        XCTAssertNotEqual(session.server!.id, previousID)
    }

    func testSelectServerEmitsEditEvent() {
        let server1 = Server(name: "Server 1", type: .deluge, data: Data(), keychainData: nil)
        let server2 = Server(name: "Server 2", type: .deluge, data: Data(), keychainData: nil)
        preferences.addOrUpdate(server: server1)
        preferences.addOrUpdate(server: server2)

        var server: Server!
        viewModel.events.first().sink {
            guard case let .edit(server: inner) = $0 else {
                XCTFail("Unexpected event")
                return
            }
            server = inner
        }.store(in: &observers)
        viewModel.handle(.selectServer(index: 1))
        XCTAssertEqual(server.id, server2.id)
    }

    func testAddServerEmitsAddServerEvent() {
        let expectation = self.expectation(description: "Value received")
        viewModel.events.first().sink {
            guard case .addServer = $0 else {
                XCTFail("Unexpected event")
                return
            }
            expectation.fulfill()
        }.store(in: &observers)
        viewModel.handle(.addServer)
        waitForExpectations(timeout: 0)
    }
}
