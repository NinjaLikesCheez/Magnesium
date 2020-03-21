import Combine
@testable import Magnesium
import Preferences
import Transmission
import XCTest

class TransmissionSettingsViewModelTests: XCTestCase {
    private var client: MockTransmissionClient!
    private var addViewModel: TransmissionSettingsViewModel!
    private var server: Server!
    private var editViewModel: TransmissionSettingsViewModel!
    private var cancellables: Set<AnyCancellable>!
    private var preferences: Preferences { Current.preferences }

    override func setUp() {
        super.setUp()
        client = MockTransmissionClient()
        Current = .mock(transmission: { _, _, _ in self.client })
        addViewModel = TransmissionSettingsViewModel()
        let settings = TransmissionServerSettings(url: URL(string: "http://example.com")!, username: "username")
        let keychain = TransmissionKeychainData(password: "password")
        let encoder = JSONEncoder()
        server = Server(
            name: "Server",
            type: .transmission,
            data: try! encoder.encode(settings),
            keychainData: try! encoder.encode(keychain)
        )
        editViewModel = TransmissionSettingsViewModel(server: server)
        cancellables = Set()
    }

    func test_inputs() {
        XCTAssertEqual(addViewModel.view.inputs.map { $0.name }, ["name", "server", "username", "password"])
    }

    func test_name_withServer_shouldUseExisting() {
        XCTAssertEqual(editViewModel.view.inputs[0].value.value, "Server")
    }

    func test_serverURL_withServer_shouldUseExisting() {
        XCTAssertEqual(editViewModel.view.inputs[1].value.value, "http://example.com")
    }

    func test_username_withServer_shouldUseExisting() {
        XCTAssertEqual(editViewModel.view.inputs[2].value.value, "username")
    }

    func test_password_withServer_shouldUseExisting() {
        XCTAssertEqual(editViewModel.view.inputs[3].value.value, "password")
    }

    func test_title_withoutServer() {
        XCTAssertEqual(addViewModel.view.title, "Add Server")
    }

    func test_title_withServer() {
        XCTAssertEqual(editViewModel.view.title, "Edit Server")
    }

    func test_saveButtonTitle_withoutServer() {
        XCTAssertEqual(addViewModel.view.saveButtonTitle, "Add")
    }

    func test_saveButtonTitle_withServer() {
        XCTAssertEqual(editViewModel.view.saveButtonTitle, "Save")
    }

    func test_canDelete_withoutServer() {
        XCTAssertFalse(addViewModel.view.canDelete)
    }

    func test_canDelete_withServer() {
        XCTAssertTrue(editViewModel.view.canDelete)
    }

    private func isSaveButtonEnabled(_ viewModel: TransmissionSettingsViewModel) -> Bool {
        var value: Bool!
        _ = viewModel.view.isSaveButtonEnabled.sink {
            value = $0
        }
        return value
    }

    func test_isSaveButtonEnabled_withValidData_shouldBeTrue() {
        let viewModel = addViewModel!
        XCTAssertFalse(isSaveButtonEnabled(viewModel))
        viewModel.view.inputs[0].value.value = "name"
        XCTAssertFalse(isSaveButtonEnabled(viewModel))
        viewModel.view.inputs[1].value.value = "http://example.com"
        XCTAssertTrue(isSaveButtonEnabled(viewModel))
    }

    func test_isSaveButtonEnabled_withInvalidServer_shouldBeFalse() {
        let viewModel = addViewModel!
        viewModel.view.inputs[0].value.value = "name"
        viewModel.view.inputs[1].value.value = "web://site"
        var event: ServerSettingsViewModelEvent?
        viewModel.events.first().sink { event = $0 }.store(in: &cancellables)
        viewModel.receive(.saveSelected)
        guard case let .alert(alert) = event else {
            XCTFail("Unexpected event: \(String(describing: event))")
            return
        }
        XCTAssertEqual(alert.title, "Unable to Add Server")
        XCTAssertEqual(
            alert.message,
            "The server URL is invalid. Ensure the URL begins with \"http://\" or \"https://\"."
        )
        XCTAssertEqual(alert.actions.map(\.title), ["OK"])
    }

    func test_saveSelected_shouldChangeIsLoading() {
        let viewModel = addViewModel!
        viewModel.view.inputs[0].value.value = "name"
        viewModel.view.inputs[1].value.value = "http://example.com"

        var values = [Bool]()
        viewModel.view.isLoading.dropFirst().sink {
            values.append($0)
        }.store(in: &cancellables)

        viewModel.receive(.saveSelected)
        XCTAssertEqual(values, [true, false])
    }

    func test_saveSelected_shouldRequestRPCVersion() {
        let viewModel = addViewModel!
        viewModel.view.inputs[0].value.value = "name"
        viewModel.view.inputs[1].value.value = "http://example.com"
        viewModel.receive(.saveSelected)
        XCTAssertEqual(client.requestParamRequest.map(\.method), ["session-get"])
        XCTAssertEqual(client.requestParamRequest.map(\.argsJSON), [#"{"fields":["rpc-version"]}"#])
    }

    func test_saveSelected_whenAuthenticationFails_shouldEmitError() {
        client.results.append((
            "session-get",
            Fail(error: .unauthenticated).eraseToAnyPublisher()
        ))

        let viewModel = addViewModel!
        viewModel.view.inputs[0].value.value = "name"
        viewModel.view.inputs[1].value.value = "http://example.com"

        var event: ServerSettingsViewModelEvent?
        viewModel.events.first().sink { event = $0 }.store(in: &cancellables)
        viewModel.receive(.saveSelected)
        guard case let .alert(alert) = event else {
            XCTFail("Unexpected event: \(String(describing: event))")
            return
        }
        XCTAssertEqual(alert.title, "Authentication Failed")
        XCTAssertEqual(alert.message, "Unable to authenticate. Verify that your credentials are correct.")
    }

    func test_saveSelected_withoutData_shouldDoNothing() {
        let viewModel = addViewModel!
        let expectation = self.expectation(description: "Received value")
        expectation.isInverted = true
        viewModel.view.isLoading.dropFirst().sink { _ in
            expectation.fulfill()
        }.store(in: &cancellables)
        viewModel.receive(.saveSelected)
        waitForExpectations(timeout: 0)
    }

    func test_saveSelected_withoutServer_shouldAddServer() throws {
        client.results.append((
            method: "session-get",
            result: Just(-1).setFailureType(to: TransmissionError.self).eraseToAnyPublisher()
        ))

        let settings = TransmissionServerSettings(url: URL(string: "http://example.com")!, username: "username")
        let keychain = TransmissionKeychainData(password: "password")
        let expectedData = try JSONEncoder().encode(settings)
        let expectedKeychainData = try JSONEncoder().encode(keychain)

        let viewModel = addViewModel!
        viewModel.view.inputs[0].value.value = "name"
        viewModel.view.inputs[1].value.value = settings.url.absoluteString
        viewModel.view.inputs[2].value.value = settings.username
        viewModel.view.inputs[3].value.value = keychain.password
        viewModel.receive(.saveSelected)
        let server = preferences.getServers()[0]
        XCTAssertEqual(server.name, "name")
        XCTAssertEqual(server.data, expectedData)
        XCTAssertEqual(server.keychainData, expectedKeychainData)
    }

    func test_saveSelected_withServer_shouldUpdateServer() throws {
        client.results.append((
            method: "session-get",
            result: Just(-1).setFailureType(to: TransmissionError.self).eraseToAnyPublisher()
        ))

        let settings = TransmissionServerSettings(url: URL(string: "http://example.com")!, username: "username")
        let keychain = TransmissionKeychainData(password: "new-password")
        let expectedData = try JSONEncoder().encode(settings)
        let expectedKeychainData = try JSONEncoder().encode(keychain)

        let viewModel = editViewModel!
        viewModel.view.inputs[0].value.value = "new name"
        viewModel.view.inputs[1].value.value = settings.url.absoluteString
        viewModel.view.inputs[2].value.value = settings.username
        viewModel.view.inputs[3].value.value = keychain.password
        viewModel.receive(.saveSelected)
        let server = preferences.getServers()[0]
        XCTAssertEqual(server.name, "new name")
        XCTAssertEqual(server.data, expectedData)
        XCTAssertEqual(server.keychainData, expectedKeychainData)
    }

    func test_saveSelected_withoutServer_shouldEmitCompleteEvent() {
        client.results.append((
            method: "session-get",
            result: Just(-1).setFailureType(to: TransmissionError.self).eraseToAnyPublisher()
        ))

        let viewModel = addViewModel!
        viewModel.view.inputs[0].value.value = "name"
        viewModel.view.inputs[1].value.value = "http://example.com"
        viewModel.view.inputs[2].value.value = "password"

        var event: ServerSettingsViewModelEvent?
        viewModel.events.first().sink { event = $0 }.store(in: &cancellables)
        viewModel.receive(.saveSelected)
        guard case .complete = event else {
            XCTFail("Unexpected event: \(String(describing: event))")
            return
        }
    }

    func test_saveSelected_withServer_shouldEmitCompleteEvent() {
        client.results.append((
            method: "session-get",
            result: Just(-1).setFailureType(to: TransmissionError.self).eraseToAnyPublisher()
        ))

        let viewModel = editViewModel!
        var event: ServerSettingsViewModelEvent?
        viewModel.events.first().sink { event = $0 }.store(in: &cancellables)
        viewModel.receive(.saveSelected)
        guard case .complete = event else {
            XCTFail("Unexpected event: \(String(describing: event))")
            return
        }
    }

    func test_deleteSelected_withoutServer_shouldDoNothing() {
        let viewModel = addViewModel!
        let expectation = self.expectation(description: "Value received")
        expectation.isInverted = true
        viewModel.events.first().sink { _ in
            expectation.fulfill()
        }.store(in: &cancellables)
        viewModel.receive(.deleteSelected(source: .view(UIView(), rect: .zero)))
        waitForExpectations(timeout: 0)
    }

    func test_deleteSelected_withServer_shouldEmitAlert() {
        let viewModel = editViewModel!
        var event: ServerSettingsViewModelEvent?
        viewModel.events.first().sink { event = $0 }.store(in: &cancellables)
        viewModel.receive(.deleteSelected(source: .view(UIView(), rect: .zero)))
        guard case let .alert(alert) = event else {
            XCTFail("Unexpected event: \(String(describing: event))")
            return
        }
        XCTAssertNil(alert.title)
        XCTAssertEqual(alert.message, "Are you sure you want to delete this server?")
        XCTAssertEqual(alert.actions[0].title, "Delete Server")
        XCTAssertEqual(alert.actions[0].style, AlertAction.Style.destructive)
        XCTAssertEqual(alert.actions[1].title, "Cancel")
    }

    func test_deleteSelected_whenDeleteServerSelected_shouldRemoveServer() {
        preferences.addOrUpdate(server: server)
        let viewModel = editViewModel!
        var event: ServerSettingsViewModelEvent?
        viewModel.events.first().sink { event = $0 }.store(in: &cancellables)
        viewModel.receive(.deleteSelected(source: .view(UIView(), rect: .zero)))
        guard case let .alert(alert) = event else {
            XCTFail("Unexpected event: \(String(describing: event))")
            return
        }
        alert.actions.first { $0.title == "Delete Server" }?.handler?()
        XCTAssertTrue(preferences.getServers().isEmpty)
    }

    func test_deleteSelected_whenDeleteServerSelected_shouldEmitCompleteEvent() {
        preferences.addOrUpdate(server: server)
        let viewModel = editViewModel!

        var event: ServerSettingsViewModelEvent?
        viewModel.events.first().sink { event = $0 }.store(in: &cancellables)
        viewModel.receive(.deleteSelected(source: .view(UIView(), rect: .zero)))
        guard case let .alert(alert) = event else {
            XCTFail("Unexpected event: \(String(describing: event))")
            return
        }

        event = nil
        viewModel.events.first().sink { event = $0 }.store(in: &cancellables)
        alert.actions.first { $0.title == "Delete Server" }?.handler?()
        XCTAssertTrue(preferences.getServers().isEmpty)
        guard case .complete = event else {
            XCTFail("Unexpected event: \(String(describing: event))")
            return
        }
    }
}
