import Combine
@testable import Magnesium
import Preferences
import XCTest

class ServerPreferencesTests: XCTestCase {
    private var server: Server!
    private var keychainStore: Keychain.MockStore!
    private var cancellables: Set<AnyCancellable>!
    private var preferences: Preferences { Current.preferences }

    override func setUp() {
        super.setUp()
        keychainStore = .init()
        Current = .mock(keychain: .mock(store: keychainStore))
        server = Server(name: "Server 1", type: .deluge, data: Data(), keychainData: nil)
        cancellables = Set()
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
        }.store(in: &cancellables)
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
            .store(in: &cancellables)
        var server = self.server!
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
        }.store(in: &cancellables)
        preferences.addOrUpdate(server: server)
        waitForExpectations(timeout: 0)
    }

    func test_serverUpdatedPublisher_withDeletedServer_shouldEmitNil() {
        preferences.addOrUpdate(server: server)
        let expectation = self.expectation(description: "Value received")
        preferences.serverUpdatedPublisher(for: server).first().sink { updated in
            XCTAssertNil(updated)
            expectation.fulfill()
        }.store(in: &cancellables)
        preferences.remove(server: server)
        waitForExpectations(timeout: 0)
    }

    func test_addOrUpdate_withKeychainData_shouldPersistToKeychain() {
        let server = Server(name: "Server 1", type: .deluge, data: Data(), keychainData: Data(count: 1024))
        preferences.addOrUpdate(server: server)
        let fetched = preferences.getServers().first!
        XCTAssertEqual(keychainStore.values.count, 1)
        XCTAssertEqual(fetched.keychainData, server.keychainData)
    }

    func test_removeServer_withKeychainData_shouldRemoveFromKeychain() {
        let server = Server(name: "Server 1", type: .deluge, data: Data(), keychainData: Data(count: 1024))
        preferences.addOrUpdate(server: server)
        XCTAssertEqual(keychainStore.values.count, 1)
        preferences.remove(server: server)
        XCTAssertEqual(keychainStore.values.count, 0)
    }

    func test_removeServers_shouldRemoveKeychainData() {
        let server = Server(name: "Server 1", type: .deluge, data: Data(), keychainData: Data(count: 1024))
        preferences.addOrUpdate(server: server)
        XCTAssertEqual(keychainStore.values.count, 1)
        preferences.removeServers()
        XCTAssertEqual(keychainStore.values.count, 0)
    }
}
