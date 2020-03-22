import Combine
import Keychain
@testable import Magnesium
import Preferences
import XCTest

class ServerPreferencesTests: XCTestCase {
    private var server: Server!
    private var keychainStore: InMemoryKeychain.Store!
    private var preferences: Preferences { Current.preferences }

    override func setUp() {
        super.setUp()
        keychainStore = .init()
        Current = .mock(keychain: InMemoryKeychain(store: keychainStore))
        server = Server(name: "Server 1", type: .deluge, data: Data(), keychainData: nil)
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

    func test_serverUpdatePublisher_withNewServer_shouldEmit() throws {
        let updated = try preferences.serverUpdatedPublisher(for: server).wait().first {
            self.preferences.addOrUpdate(server: self.server)
        }.unwrap()
        XCTAssertEqual(server, updated)
    }

    func test_serverUpdatedPublisher_withExistingServer_shouldEmitUpdatedServer() throws {
        preferences.addOrUpdate(server: server)
        var server = self.server!
        server.name = "New Name"
        let updated = try preferences.serverUpdatedPublisher(for: server).wait().first {
            self.preferences.addOrUpdate(server: server)
        }.unwrap()
        XCTAssertEqual(updated?.id, self.server.id)
        XCTAssertEqual(updated?.name, "New Name")
    }

    func test_serverUpdatedPublisher_withSameServer_shouldNotEmit() {
        preferences.addOrUpdate(server: server)
        let optional = preferences.serverUpdatedPublisher(for: server).wait().first {
            self.preferences.addOrUpdate(server: self.server)
        }
        XCTAssertEqual(optional, .none)
    }

    func test_serverUpdatedPublisher_withDeletedServer_shouldEmitNil() throws {
        preferences.addOrUpdate(server: server)
        let updated = try preferences.serverUpdatedPublisher(for: server).wait().first {
            self.preferences.remove(server: self.server)
        }.unwrap()
        XCTAssertNil(updated)
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
