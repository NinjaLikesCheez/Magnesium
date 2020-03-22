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
        let value = viewModel.view.sections.dropFirst().wait().first {
            self.preferences.addOrUpdate(server: Server(name: "", type: .deluge, data: Data(), keychainData: nil))
        }
        XCTAssertNotNil(value)
    }

    func test_sections_whenCurrentServerChanged_shouldEmit() {
        let value = viewModel.view.sections.dropFirst().wait().first {
            self.session.setServer(Server(name: "", type: .deluge, data: Data(), keychainData: nil))
        }
        XCTAssertNotNil(value)
    }

    func test_doneSelected_shouldEmitCompleteEvent() {
        let event = viewModel.events.wait().first {
            self.viewModel.receive(.doneSelected)
        }

        guard case .complete = event else {
            XCTFail("Unexpected event: \(String(describing: event))")
            return
        }
    }

    func test_changeServerSelected_shouldEmitAlert() {
        let server1 = Server(name: "Server 1", type: .deluge, data: Data(), keychainData: nil)
        let server2 = Server(name: "Server 2", type: .deluge, data: Data(), keychainData: nil)
        preferences.addOrUpdate(server: server1)
        preferences.addOrUpdate(server: server2)

        let event = viewModel.events.wait().first {
            self.viewModel.receive(.changeServerSelected(source: .view(UIView(), rect: .zero)))
        }

        guard case let .alert(alert) = event else {
            XCTFail("Unexpected event: \(String(describing: event))")
            return
        }

        let expected = ["Server 1", "Server 2", "Cancel"]
        XCTAssertEqual(alert.actions.map { $0.title ?? "" }, expected)
    }

    func test_changeServerSelected_whenServerSelected_shouldUpdateSession() {
        let server1 = Server(name: "Server 1", type: .deluge, data: Data(), keychainData: nil)
        let server2 = Server(name: "Server 2", type: .deluge, data: Data(), keychainData: nil)
        preferences.addOrUpdate(server: server1)
        preferences.addOrUpdate(server: server2)
        session.setServer(server1)

        let event = viewModel.events.wait().first {
            self.viewModel.receive(.changeServerSelected(source: .view(UIView(), rect: .zero)))
        }

        guard case let .alert(alert) = event else {
            XCTFail("Unexpected event: \(String(describing: event))")
            return
        }

        let previousID = session.server!.id
        alert.actions.first { $0.title == "Server 2" }?.handler?()
        XCTAssertNotEqual(session.server!.id, previousID)
    }

    func test_serverSelected_shouldEmitEditServerEvent() {
        let server1 = Server(name: "Server 1", type: .deluge, data: Data(), keychainData: nil)
        let server2 = Server(name: "Server 2", type: .deluge, data: Data(), keychainData: nil)
        preferences.addOrUpdate(server: server1)
        preferences.addOrUpdate(server: server2)

        let event = viewModel.events.wait().first {
            self.viewModel.receive(.serverSelected(index: 1))
        }

        guard case let .editServer(server) = event else {
            XCTFail("Unexpected event: \(String(describing: event))")
            return
        }

        XCTAssertEqual(server.id, server2.id)
    }

    func test_addServerSelected_shouldEmitAddServerEvent() {
        let event = viewModel.events.wait().first {
            self.viewModel.receive(.addServerSelected)
        }

        guard case .addServer = event else {
            XCTFail("Unexpected event: \(String(describing: event))")
            return
        }
    }

    func test_refreshIntervalSelected_shouldEmitShowRefreshIntervalSettingsEvent() {
        let event = viewModel.events.wait().first {
            self.viewModel.receive(.refreshIntervalSelected)
        }

        guard case .showRefreshIntervalSettings = event else {
            XCTFail("Unexpected event: \(String(describing: event))")
            return
        }
    }
}
