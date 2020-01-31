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

    func test_sections_whenServersChanged_shouldEmit() {
        let expectation = self.expectation(description: "Value received")
        viewModel.state.sections.dropFirst().first().sink { _ in
            expectation.fulfill()
        }.store(in: &observers)
        preferences.addOrUpdate(server: Server(name: "", type: .deluge, data: Data(), keychainData: nil))
        waitForExpectations(timeout: 0)
    }

    func test_sections_whenCurrentServerChanged_shouldEmit() {
        let expectation = self.expectation(description: "Value received")
        viewModel.state.sections.dropFirst().first().sink { _ in
            expectation.fulfill()
        }.store(in: &observers)
        session.setServer(Server(name: "", type: .deluge, data: Data(), keychainData: nil))
        waitForExpectations(timeout: 0)
    }

    func test_doneSelected_shouldEmitCompleteEvent() {
        let expectation = self.expectation(description: "Value received")
        viewModel.events.first().sink {
            guard case .complete = $0 else {
                XCTFail("Unexpected event")
                return
            }
            expectation.fulfill()
        }.store(in: &observers)
        viewModel.handle(.doneSelected)
        waitForExpectations(timeout: 0)
    }

    func test_changeServerSelected_shouldEmitAlert() {
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

        viewModel.handle(.changeServerSelected(source: .view(UIView(), rect: .zero)))
        let expected = ["Server 1", "Server 2", "Cancel"]
        XCTAssertEqual(alert?.actions.map { $0.title ?? "" }, expected)
    }

    func test_changeServerSelected_whenServerSelected_shouldUpdateSession() {
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
        viewModel.handle(.changeServerSelected(source: .view(UIView(), rect: .zero)))
        let changeServer = alert!.actions[1].handler!

        let previousID = session.server!.id
        changeServer()
        XCTAssertNotEqual(session.server!.id, previousID)
    }

    func test_serverSelected_shouldEmitEditEvent() {
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
        viewModel.handle(.serverSelected(index: 1))
        XCTAssertEqual(server.id, server2.id)
    }

    func test_addServerSelected_shouldEmitAddServerEvent() {
        let expectation = self.expectation(description: "Value received")
        viewModel.events.first().sink {
            guard case .addServer = $0 else {
                XCTFail("Unexpected event")
                return
            }
            expectation.fulfill()
        }.store(in: &observers)
        viewModel.handle(.addServerSelected)
        waitForExpectations(timeout: 0)
    }
}
