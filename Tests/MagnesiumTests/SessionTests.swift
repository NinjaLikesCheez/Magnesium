import Combine
@testable import Magnesium
import Preferences
import XCTest

class SessionTests: TestCase {
    private var session: Session!
    private var preferences: Preferences { Current.preferences }

    override func setUp() {
        super.setUp()
        session = Session()
    }

    func test_serverPublisher_shouldHaveInitialValue() throws {
        let server = try session.serverPublisher.first().wait().singleValue()
        XCTAssertNil(server)
    }

    func test_serverPublisher_whenFirstServerAdded_shouldEmit() throws {
        let server = Server(name: "Server", type: .deluge, data: Data(), keychainData: nil)
        let updated = try session.serverPublisher.dropFirst().first().wait {
            try! self.preferences.addOrUpdate(server: server)
        }.singleValue()
        XCTAssertEqual(updated, server)
        XCTAssertEqual(session.server, server)
    }

    func test_serverPublisher_whenServerUpdated_shouldEmit() throws {
        var server = Server(name: "Server", type: .deluge, data: Data(), keychainData: nil)
        try preferences.addOrUpdate(server: server)
        server.name = "New Name"
        let updated = try session.serverPublisher.dropFirst().first().wait {
            try! self.preferences.addOrUpdate(server: server)
        }.singleValue()
        XCTAssertEqual(updated, server)
        XCTAssertEqual(session.server, server)
    }

    func test_serverPublisher_whenServerDeleted_shouldEmitNextServer() throws {
        let firstServer = Server(name: "Server 1", type: .deluge, data: Data(), keychainData: nil)
        let secondServer = Server(name: "Server 2", type: .deluge, data: Data(), keychainData: nil)
        try preferences.addOrUpdate(server: firstServer)
        try preferences.addOrUpdate(server: secondServer)
        XCTAssertEqual(session.server, firstServer)
        let updated = try session.serverPublisher.dropFirst().first().wait {
            try! self.preferences.remove(server: firstServer)
        }.singleValue()
        XCTAssertEqual(updated, secondServer)
        XCTAssertEqual(session.server, secondServer)
    }

    func test_serverPublisher_whenPreferencesChanged_shouldNotEmit() throws {
        let firstServer = Server(name: "Server 1", type: .deluge, data: Data(), keychainData: nil)
        let secondServer = Server(name: "Server 2", type: .deluge, data: Data(), keychainData: nil)
        try preferences.addOrUpdate(server: firstServer)
        try preferences.addOrUpdate(server: secondServer)
        XCTAssertEqual(session.server, firstServer)
        let result = session.serverPublisher.dropFirst().first().wait {
            self.preferences[.selectedServerID] = secondServer.id
        }
        XCTAssertTrue(result.values().isEmpty)
        XCTAssertEqual(session.server, firstServer)
    }

    func test_serverPublisher_whenServerChanged_shouldEmit() throws {
        let firstServer = Server(name: "Server 1", type: .deluge, data: Data(), keychainData: nil)
        let secondServer = Server(name: "Server 2", type: .deluge, data: Data(), keychainData: nil)
        try preferences.addOrUpdate(server: firstServer)
        try preferences.addOrUpdate(server: secondServer)
        XCTAssertEqual(session.server, firstServer)
        let updated = try session.serverPublisher.dropFirst().first().wait {
            self.session.setServer(secondServer)
        }.singleValue()
        XCTAssertEqual(updated, secondServer)
        XCTAssertEqual(session.server, secondServer)
    }
}
