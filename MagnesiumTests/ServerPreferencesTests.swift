//
//  ServerPreferencesTests.swift
//  MagnesiumTests
//
//  Created by James Hurst on 2020-01-09.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
@testable import Magnesium
import XCTest

class ServerPreferencesTests: XCTestCase {
    private let preferences = MockPreferences()
    private let server = Server(name: "Server 1", type: .deluge, data: Data(), keychainData: nil)
    private var observers = [AnyCancellable]()

    override func setUp() {
        super.setUp()
        clearKeychain()
    }

    override func tearDown() {
        super.tearDown()
        clearKeychain()
    }

    private func clearKeychain() {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword]
        SecItemDelete(query as CFDictionary)
    }

    func test_addOrUpdate_withNewServer() {
        preferences.addOrUpdate(server: server)
        XCTAssertEqual(preferences.getServers().count, 1)
        XCTAssertEqual(preferences.getServers()[0], server)
    }

    func test_removeServer() {
        preferences.addOrUpdate(server: server)
        XCTAssertEqual(preferences.getServers().count, 1)
        preferences.remove(server: server)
        XCTAssertEqual(preferences.getServers().count, 0)
    }

    func test_removeServers() {
        preferences.addOrUpdate(server: server)
        XCTAssertEqual(preferences.getServers().count, 1)
        preferences.removeServers()
        XCTAssertEqual(preferences.getServers().count, 0)
    }

    func test_addOrUpdate_withExistingServer_shouldNotDuplicate() {
        preferences.addOrUpdate(server: server)
        XCTAssertEqual(preferences.getServers().count, 1)
        preferences.addOrUpdate(server: server)
        XCTAssertEqual(preferences.getServers().count, 1)
    }

    func test_serverUpdatePublisher_withNewServer_shouldEmit() {
        let expectation = self.expectation(description: "Value received")
        preferences.serverUpdatedPublisher(for: server).first().sink { updated in
            XCTAssertEqual(updated, self.server)
            expectation.fulfill()
        }.store(in: &observers)
        preferences.addOrUpdate(server: server)
        waitForExpectations(timeout: 0)
    }

    func test_serverUpdatedPublisher_withExistingServer_shouldEmitUpdatedServer() {
        preferences.addOrUpdate(server: server)
        let expectation = self.expectation(description: "Value received")
        preferences.serverUpdatedPublisher(for: server)
            .first()
            .sink { updated in
                XCTAssertEqual(updated?.id, self.server.id)
                XCTAssertEqual(updated?.name, "New Name")
                expectation.fulfill()
            }
            .store(in: &observers)
        var server = self.server
        server.name = "New Name"
        preferences.addOrUpdate(server: server)
        waitForExpectations(timeout: 0)
    }

    func test_serverUpdatedPublisher_withSameServer_shouldNotEmit() {
        preferences.addOrUpdate(server: server)
        let expectation = self.expectation(description: "Value received")
        expectation.isInverted = true
        preferences.serverUpdatedPublisher(for: server).first().sink { _ in
            expectation.fulfill()
        }.store(in: &observers)
        preferences.addOrUpdate(server: server)
        waitForExpectations(timeout: 0)
    }

    func test_serverUpdatedPublisher_withDeletedServer_shouldEmitNil() {
        preferences.addOrUpdate(server: server)
        let expectation = self.expectation(description: "Value received")
        preferences.serverUpdatedPublisher(for: server).first().sink { updated in
            XCTAssertNil(updated)
            expectation.fulfill()
        }.store(in: &observers)
        preferences.remove(server: server)
        waitForExpectations(timeout: 0)
    }

    private func getKeychainCount() -> Int {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitAll,
        ]

        var result: AnyObject?
        let status = withUnsafeMutablePointer(to: &result) {
            SecItemCopyMatching(query as CFDictionary, $0)
        }

        if status == errSecItemNotFound {
            return 0
        }

        guard status == errSecSuccess else {
            XCTFail("SecItemCopyMatching returned \(status)")
            return -1
        }

        guard let items = result as? [[String: Any]] else {
            XCTFail("Unable to cast result")
            return -1
        }

        return items.count
    }

    func test_addOrUpdate_withKeychainData_shouldPersistToKeychain() {
        let server = Server(name: "Server 1", type: .deluge, data: Data(), keychainData: Data(count: 1024))
        preferences.addOrUpdate(server: server)
        let fetched = preferences.getServers().first!
        XCTAssertEqual(getKeychainCount(), 1)
        XCTAssertEqual(fetched.keychainData, server.keychainData)
    }

    func test_removeServer_withKeychainData_shouldRemoveFromKeychain() {
        let server = Server(name: "Server 1", type: .deluge, data: Data(), keychainData: Data(count: 1024))
        preferences.addOrUpdate(server: server)
        XCTAssertEqual(getKeychainCount(), 1)
        preferences.remove(server: server)
        XCTAssertEqual(getKeychainCount(), 0)
    }

    func test_removeServers_shouldRemoveKeychainData() {
        let server = Server(name: "Server 1", type: .deluge, data: Data(), keychainData: Data(count: 1024))
        preferences.addOrUpdate(server: server)
        XCTAssertEqual(getKeychainCount(), 1)
        preferences.removeServers()
        XCTAssertEqual(getKeychainCount(), 0)
    }
}
