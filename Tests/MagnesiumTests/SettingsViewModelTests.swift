import Combine
@testable import Magnesium
import Preferences
import XCTest

class SettingsViewModelTests: TestCase {
    private var session: Session!
    private var viewModel: SettingsViewModel!
    private var preferences: Preferences { Current.preferences }

    override func setUp() {
        super.setUp()
        session = Session()
        viewModel = SettingsViewModel(session: session)
    }

    func test_sections_whenServersChanged_shouldEmit() {
        let value = viewModel.values.sections.dropFirst().first().wait {
            try! self.preferences.addOrUpdate(server: Server(name: "", type: .deluge, data: Data(), keychainData: nil))
        }
        XCTAssertNotNil(value)
    }

    func test_sections_whenCurrentServerChanged_shouldEmit() {
        let value = viewModel.values.sections.dropFirst().first().wait {
            self.session.setServer(Server(name: "", type: .deluge, data: Data(), keychainData: nil))
        }
        XCTAssertNotNil(value)
    }

    func test_doneSelected_shouldEmitCompleteEvent() throws {
        let event = try viewModel.eventPublisher.first().wait {
            self.viewModel.send(.doneSelected)
        }.singleValue()
        XCTAssertCase(event, .complete)
    }

    func test_changeServerSelected_shouldEmitAlert() throws {
        let server1 = Server(name: "Server 1", type: .deluge, data: Data(), keychainData: nil)
        let server2 = Server(name: "Server 2", type: .deluge, data: Data(), keychainData: nil)
        try preferences.addOrUpdate(server: server1)
        try preferences.addOrUpdate(server: server2)

        let event = try viewModel.eventPublisher.first().wait {
            self.viewModel.send(.changeServerSelected(source: .view(UIView(), rect: .zero)))
        }.singleValue()
        let alert = try extract(case: type(of: event).alert, from: event)
        XCTAssertEqual(alert.actions.map(\.title), ["Server 1", "Server 2", L10n.Action.cancel])
    }

    func test_changeServerSelected_whenServerSelected_shouldUpdateSession() throws {
        let server1 = Server(name: "Server 1", type: .deluge, data: Data(), keychainData: nil)
        let server2 = Server(name: "Server 2", type: .deluge, data: Data(), keychainData: nil)
        try preferences.addOrUpdate(server: server1)
        try preferences.addOrUpdate(server: server2)
        session.setServer(server1)

        let event = try viewModel.eventPublisher.first().wait {
            self.viewModel.send(.changeServerSelected(source: .view(UIView(), rect: .zero)))
        }.singleValue()
        let alert = try extract(case: type(of: event).alert, from: event)
        let previousID = session.server!.id
        alert.actions.first { $0.title == "Server 2" }?.handler?()
        XCTAssertNotEqual(session.server!.id, previousID)
    }

    func test_serverSelected_shouldEmitEditServerEvent() throws {
        let server1 = Server(name: "Server 1", type: .deluge, data: Data(), keychainData: nil)
        let server2 = Server(name: "Server 2", type: .deluge, data: Data(), keychainData: nil)
        try preferences.addOrUpdate(server: server1)
        try preferences.addOrUpdate(server: server2)

        let event = try viewModel.eventPublisher.first().wait {
            self.viewModel.send(.serverSelected(index: 1))
        }.singleValue()
        let server = try extract(case: type(of: event).editServer, from: event)
        XCTAssertEqual(server.id, server2.id)
    }

    func test_addServerSelected_shouldEmitAddServerEvent() throws {
        let event = try viewModel.eventPublisher.first().wait {
            self.viewModel.send(.addServerSelected)
        }.singleValue()
        XCTAssertCase(event, .addServer)
    }

    func test_refreshIntervalSelected_shouldEmitShowRefreshIntervalSettingsEvent() throws {
        let event = try viewModel.eventPublisher.first().wait {
            self.viewModel.send(.refreshIntervalSelected)
        }.singleValue()
        XCTAssertCase(event, .showRefreshIntervalSettings)
    }
}
