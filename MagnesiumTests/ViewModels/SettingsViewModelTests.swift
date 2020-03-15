import Combine
@testable import Magnesium
import Preferences
import XCTest

class SettingsViewModelTests: XCTestCase {
    private let preferences = InMemoryPreferences()
    private var cancellables = Set<AnyCancellable>()
    private lazy var session = Session(preferences: preferences)
    private lazy var viewModel = SettingsViewModel(session: session, preferences: preferences)

    func test_sections_whenServersChanged_shouldEmit() {
        let expectation = self.expectation(description: "Value received")
        viewModel.state.sections.dropFirst().first().sink { _ in
            expectation.fulfill()
        }.store(in: &cancellables)
        preferences.addOrUpdate(server: Server(name: "", type: .deluge, data: Data(), keychainData: nil))
        waitForExpectations(timeout: 0)
    }

    func test_sections_whenCurrentServerChanged_shouldEmit() {
        let expectation = self.expectation(description: "Value received")
        viewModel.state.sections.dropFirst().first().sink { _ in
            expectation.fulfill()
        }.store(in: &cancellables)
        session.setServer(Server(name: "", type: .deluge, data: Data(), keychainData: nil))
        waitForExpectations(timeout: 0)
    }

    func test_doneSelected_shouldEmitCompleteEvent() {
        var event: SettingsEvent?
        viewModel.events.first().sink {
            event = $0
        }.store(in: &cancellables)
        viewModel.handle(.doneSelected)
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

        var event: SettingsEvent?
        viewModel.events.first().sink { event = $0 }.store(in: &cancellables)
        viewModel.handle(.changeServerSelected(source: .view(UIView(), rect: .zero)))
        guard case let .alert(alert, _) = event else {
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

        var event: SettingsEvent?
        viewModel.events.first().sink { event = $0 }.store(in: &cancellables)
        viewModel.handle(.changeServerSelected(source: .view(UIView(), rect: .zero)))
        guard case let .alert(alert, _) = event else {
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

        var event: SettingsEvent?
        viewModel.events.first().sink { event = $0 }.store(in: &cancellables)
        viewModel.handle(.serverSelected(index: 1))
        guard case let .editServer(server) = event else {
            XCTFail("Unexpected event: \(String(describing: event))")
            return
        }
        XCTAssertEqual(server.id, server2.id)
    }

    func test_addServerSelected_shouldEmitAddServerEvent() {
        var event: SettingsEvent?
        viewModel.events.first().sink {
            event = $0
        }.store(in: &cancellables)
        viewModel.handle(.addServerSelected)
        guard case .addServer = event else {
            XCTFail("Unexpected event: \(String(describing: event))")
            return
        }
    }

    func test_refreshIntervalSelected_shouldEmitShowRefreshIntervalSettingsEvent() {
        var event: SettingsEvent?
        viewModel.events.first().sink {
            event = $0
        }.store(in: &cancellables)
        viewModel.handle(.refreshIntervalSelected)
        guard case .showRefreshIntervalSettings = event else {
            XCTFail("Unexpected event: \(String(describing: event))")
            return
        }
    }
}
