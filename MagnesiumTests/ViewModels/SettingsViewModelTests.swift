import Combine
@testable import Magnesium
import Preferences
import XCTest

class SettingsViewModelTests: XCTestCase {
    private var session: Session!
    private var viewModel: SettingsViewModel!
    private var cancellables: Set<AnyCancellable>!
    private var preferences: Preferences { Current.preferences }

    override func setUp() {
        super.setUp()
        Current = .mock
        session = Session()
        viewModel = SettingsViewModel(session: session)
        cancellables = Set()
    }

    func test_sections_whenServersChanged_shouldEmit() {
        let value = viewModel.view.sections.dropFirst().first().wait {
            self.preferences.addOrUpdate(server: Server(name: "", type: .deluge, data: Data(), keychainData: nil))
        }
        XCTAssertNotNil(value)
    }

    func test_sections_whenCurrentServerChanged_shouldEmit() {
        let value = viewModel.view.sections.dropFirst().first().wait {
            self.session.setServer(Server(name: "", type: .deluge, data: Data(), keychainData: nil))
        }
        XCTAssertNotNil(value)
    }

    func test_doneSelected_shouldEmitCompleteEvent() throws {
        let event = try viewModel.events.first().wait {
            self.viewModel.receive(.doneSelected)
        }.value()

        guard case .complete = event else {
            XCTFail("Unexpected event: \(String(describing: event))")
            return
        }
    }

    func test_changeServerSelected_shouldEmitAlert() throws {
        let server1 = Server(name: "Server 1", type: .deluge, data: Data(), keychainData: nil)
        let server2 = Server(name: "Server 2", type: .deluge, data: Data(), keychainData: nil)
        preferences.addOrUpdate(server: server1)
        preferences.addOrUpdate(server: server2)

        let event = try viewModel.events.first().wait {
            self.viewModel.receive(.changeServerSelected(source: .view(UIView(), rect: .zero)))
        }.value()

        guard case let .alert(alert) = event else {
            XCTFail("Unexpected event: \(String(describing: event))")
            return
        }

        let expected = ["Server 1", "Server 2", "Cancel"]
        XCTAssertEqual(alert.actions.map { $0.title ?? "" }, expected)
    }

    func test_changeServerSelected_whenServerSelected_shouldUpdateSession() throws {
        let server1 = Server(name: "Server 1", type: .deluge, data: Data(), keychainData: nil)
        let server2 = Server(name: "Server 2", type: .deluge, data: Data(), keychainData: nil)
        preferences.addOrUpdate(server: server1)
        preferences.addOrUpdate(server: server2)
        session.setServer(server1)

        let event = try viewModel.events.first().wait {
            self.viewModel.receive(.changeServerSelected(source: .view(UIView(), rect: .zero)))
        }.value()

        guard case let .alert(alert) = event else {
            XCTFail("Unexpected event: \(String(describing: event))")
            return
        }

        let previousID = session.server!.id
        alert.actions.first { $0.title == "Server 2" }?.handler?()
        XCTAssertNotEqual(session.server!.id, previousID)
    }

    func test_serverSelected_shouldEmitEditServerEvent() throws {
        let server1 = Server(name: "Server 1", type: .deluge, data: Data(), keychainData: nil)
        let server2 = Server(name: "Server 2", type: .deluge, data: Data(), keychainData: nil)
        preferences.addOrUpdate(server: server1)
        preferences.addOrUpdate(server: server2)

        let event = try viewModel.events.first().wait {
            self.viewModel.receive(.serverSelected(index: 1))
        }.value()

        guard case let .editServer(server) = event else {
            XCTFail("Unexpected event: \(String(describing: event))")
            return
        }

        XCTAssertEqual(server.id, server2.id)
    }

    func test_addServerSelected_shouldEmitAddServerEvent() throws {
        let event = try viewModel.events.first().wait {
            self.viewModel.receive(.addServerSelected)
        }.value()

        guard case .addServer = event else {
            XCTFail("Unexpected event: \(String(describing: event))")
            return
        }
    }

    func test_refreshIntervalSelected_shouldEmitShowRefreshIntervalSettingsEvent() throws {
        let event = try viewModel.events.first().wait {
            self.viewModel.receive(.refreshIntervalSelected)
        }.value()

        guard case .showRefreshIntervalSettings = event else {
            XCTFail("Unexpected event: \(String(describing: event))")
            return
        }
    }
}
