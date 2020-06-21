import Combine
import Keychain
@testable import Magnesium
import Preferences
import XCTest

class ServerPreferencesTests: TestCase {
    private var server: Server!
    private var keychainStore: InMemoryKeychain.Store!
    private var preferences: Preferences { Current.preferences }

    override func setUp() {
        super.setUp()
        keychainStore = .init()
        Current.keychain = InMemoryKeychain(store: keychainStore)
        server = Server(name: "Server 1", type: .deluge, data: Data(), keychainData: nil)
    }

    func test_addOrUpdate_withNewServer() throws {
        try preferences.addOrUpdate(server: server)
        XCTAssertEqual(try preferences.getServers().count, 1)
        XCTAssertEqual(try preferences.getServers()[0], server)
    }

    func test_removeServer() throws {
        try preferences.addOrUpdate(server: server)
        XCTAssertEqual(try preferences.getServers().count, 1)
        try preferences.remove(server: server)
        XCTAssertEqual(try preferences.getServers().count, 0)
    }

    func test_removeServers() throws {
        try preferences.addOrUpdate(server: server)
        XCTAssertEqual(try preferences.getServers().count, 1)
        try preferences.removeServers()
        XCTAssertEqual(try preferences.getServers().count, 0)
    }

    func test_addOrUpdate_withExistingServer_shouldNotDuplicate() throws {
        try preferences.addOrUpdate(server: server)
        XCTAssertEqual(try preferences.getServers().count, 1)
        try preferences.addOrUpdate(server: server)
        XCTAssertEqual(try preferences.getServers().count, 1)
    }

    func test_serverUpdatePublisher_withNewServer_shouldEmit() throws {
        let updated = try preferences.serverUpdatedPublisher(for: server).first().wait {
            try! self.preferences.addOrUpdate(server: self.server)
        }.singleValue()
        XCTAssertEqual(server, updated)
    }

    func test_serverUpdatedPublisher_withExistingServer_shouldEmitUpdatedServer() throws {
        try preferences.addOrUpdate(server: server)
        var server = self.server!
        server.name = "New Name"
        let updated = try preferences.serverUpdatedPublisher(for: server).first().wait {
            try! self.preferences.addOrUpdate(server: server)
        }.singleValue()
        XCTAssertEqual(updated?.id, self.server.id)
        XCTAssertEqual(updated?.name, "New Name")
    }

    func test_serverUpdatedPublisher_withSameServer_shouldNotEmit() throws {
        try preferences.addOrUpdate(server: server)
        let result = preferences.serverUpdatedPublisher(for: server).first().wait {
            try! self.preferences.addOrUpdate(server: self.server)
        }
        XCTAssertTrue(result.values().isEmpty)
    }

    func test_serverUpdatedPublisher_withDeletedServer_shouldEmitNil() throws {
        try preferences.addOrUpdate(server: server)
        let updated = try preferences.serverUpdatedPublisher(for: server).first().wait {
            try! self.preferences.remove(server: self.server)
        }.singleValue()
        XCTAssertNil(updated)
    }

    func test_addOrUpdate_withKeychainData_shouldPersistToKeychain() throws {
        let server = Server(name: "Server 1", type: .deluge, data: Data(), keychainData: Data(count: 1024))
        try preferences.addOrUpdate(server: server)
        let fetched = try preferences.getServers().first!
        XCTAssertEqual(keychainStore.values.count, 1)
        XCTAssertEqual(fetched.keychainData, server.keychainData)
    }

    func test_removeServer_withKeychainData_shouldRemoveFromKeychain() throws {
        let server = Server(name: "Server 1", type: .deluge, data: Data(), keychainData: Data(count: 1024))
        try preferences.addOrUpdate(server: server)
        XCTAssertEqual(keychainStore.values.count, 1)
        try preferences.remove(server: server)
        XCTAssertEqual(keychainStore.values.count, 0)
    }

    func test_removeServers_shouldRemoveKeychainData() throws {
        let server = Server(name: "Server 1", type: .deluge, data: Data(), keychainData: Data(count: 1024))
        try preferences.addOrUpdate(server: server)
        XCTAssertEqual(keychainStore.values.count, 1)
        try preferences.removeServers()
        XCTAssertEqual(keychainStore.values.count, 0)
    }
}
