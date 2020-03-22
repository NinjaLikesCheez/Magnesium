import Combine
@testable import Magnesium
import Preferences
import XCTest

class SessionTests: XCTestCase {
    private var session: Session!
    private var preferences: Preferences { Current.preferences }

    override func setUp() {
        super.setUp()
        Current = .mock
        session = Session()
    }

    func test_serverPublisher_shouldHaveInitialValue() {
        XCTAssertEqual(session.serverPublisher.wait().first(), .some(nil))
    }

    func test_serverPublisher_whenFirstServerAdded_shouldEmit() throws {
        let server = Server(name: "Server", type: .deluge, data: Data(), keychainData: nil)
        let updated = try session.serverPublisher.dropFirst().wait().first {
            self.preferences.addOrUpdate(server: server)
        }.unwrap()
        XCTAssertEqual(updated, server)
        XCTAssertEqual(session.server, server)
    }

    func test_serverPublisher_whenServerUpdated_shouldEmit() throws {
        var server = Server(name: "Server", type: .deluge, data: Data(), keychainData: nil)
        preferences.addOrUpdate(server: server)
        server.name = "New Name"
        let updated = try session.serverPublisher.dropFirst().wait().first {
            self.preferences.addOrUpdate(server: server)
        }.unwrap()
        XCTAssertEqual(updated, server)
        XCTAssertEqual(session.server, server)
    }

    func test_serverPublisher_whenServerDeleted_shouldEmitNextServer() throws {
        let firstServer = Server(name: "Server 1", type: .deluge, data: Data(), keychainData: nil)
        let secondServer = Server(name: "Server 2", type: .deluge, data: Data(), keychainData: nil)
        preferences.addOrUpdate(server: firstServer)
        preferences.addOrUpdate(server: secondServer)
        XCTAssertEqual(session.server, firstServer)
        let updated = try session.serverPublisher.dropFirst().wait().first {
            self.preferences.remove(server: firstServer)
        }.unwrap()
        XCTAssertEqual(updated, secondServer)
        XCTAssertEqual(session.server, secondServer)
    }

    func test_serverPublisher_whenPreferencesChanged_shouldNotEmit() {
        let firstServer = Server(name: "Server 1", type: .deluge, data: Data(), keychainData: nil)
        let secondServer = Server(name: "Server 2", type: .deluge, data: Data(), keychainData: nil)
        preferences.addOrUpdate(server: firstServer)
        preferences.addOrUpdate(server: secondServer)
        XCTAssertEqual(session.server, firstServer)
        let optional = session.serverPublisher.dropFirst().wait().first {
            self.preferences[.selectedServerID] = secondServer.id
        }
        XCTAssertEqual(optional, .none)
        XCTAssertEqual(session.server, firstServer)
    }

    func test_serverPublisher_whenServerChanged_shouldEmit() throws {
        let firstServer = Server(name: "Server 1", type: .deluge, data: Data(), keychainData: nil)
        let secondServer = Server(name: "Server 2", type: .deluge, data: Data(), keychainData: nil)
        preferences.addOrUpdate(server: firstServer)
        preferences.addOrUpdate(server: secondServer)
        XCTAssertEqual(session.server, firstServer)
        let updated = try session.serverPublisher.dropFirst().wait().first {
            self.session.setServer(secondServer)
        }.unwrap()
        XCTAssertEqual(updated, secondServer)
        XCTAssertEqual(session.server, secondServer)
    }
}
