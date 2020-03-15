import Combine
import Deluge
@testable import Magnesium
import Preferences
import XCTest

class DelugeSettingsViewModelTests: XCTestCase {
    private let client = MockDelugeClient()
    private let preferences = InMemoryPreferences()
    private var cancellables = Set<AnyCancellable>()
    private lazy var clientProvider = MockClientProvider(client: client)
    private lazy var addViewModel = DelugeSettingsViewModel(
        preferences: preferences,
        clientProvider: clientProvider
    )
    private lazy var editViewModel = DelugeSettingsViewModel(
        preferences: preferences,
        server: server,
        clientProvider: clientProvider
    )
    private lazy var server: Server = {
        let settings = DelugeServerSettings(url: URL(string: "http://example.com")!)
        let keychain = DelugeKeychainData(password: "password")
        let encoder = JSONEncoder()
        return Server(
            name: "Server",
            type: .deluge,
            data: try! encoder.encode(settings),
            keychainData: try! encoder.encode(keychain)
        )
    }()

    func test_inputs() {
        XCTAssertEqual(addViewModel.state.inputs.map { $0.name }, ["name", "server", "password"])
    }

    func test_name_withServer_shouldUseExisting() {
        XCTAssertEqual(editViewModel.state.inputs[0].value.value, "Server")
    }

    func test_serverURL_withServer_shouldUseExisting() {
        XCTAssertEqual(editViewModel.state.inputs[1].value.value, "http://example.com")
    }

    func test_password_withServer_shouldUseExisting() {
        XCTAssertEqual(editViewModel.state.inputs[2].value.value, "password")
    }

    func test_title_withoutServer() {
        XCTAssertEqual(addViewModel.state.title, "Add Server")
    }

    func test_title_withServer() {
        XCTAssertEqual(editViewModel.state.title, "Edit Server")
    }

    func test_saveButtonTitle_withoutServer() {
        XCTAssertEqual(addViewModel.state.saveButtonTitle, "Add")
    }

    func test_saveButtonTitle_withServer() {
        XCTAssertEqual(editViewModel.state.saveButtonTitle, "Save")
    }

    func test_canDelete_withoutServer() {
        XCTAssertFalse(addViewModel.state.canDelete)
    }

    func test_canDelete_withServer() {
        XCTAssertTrue(editViewModel.state.canDelete)
    }

    private func isSaveButtonEnabled(_ viewModel: DelugeSettingsViewModel) -> Bool {
        var value: Bool!
        _ = viewModel.state.isSaveButtonEnabled.sink {
            value = $0
        }
        return value
    }

    func test_isSaveButtonEnabled_withValidData_shouldBeTrue() {
        let viewModel = addViewModel
        XCTAssertFalse(isSaveButtonEnabled(viewModel))
        viewModel.state.inputs[0].value.value = "name"
        XCTAssertFalse(isSaveButtonEnabled(viewModel))
        viewModel.state.inputs[1].value.value = "http://example.com"
        XCTAssertFalse(isSaveButtonEnabled(viewModel))
        viewModel.state.inputs[2].value.value = "password"
        XCTAssertTrue(isSaveButtonEnabled(viewModel))
    }

    func test_saveSelected_withInvalidServer_shouldEmitAlert() {
        let viewModel = addViewModel
        viewModel.state.inputs[0].value.value = "name"
        viewModel.state.inputs[1].value.value = "web://site"
        viewModel.state.inputs[2].value.value = "password"
        var event: ServerSettingsEvent?
        viewModel.events.first().sink { event = $0 }.store(in: &cancellables)
        viewModel.handle(.saveSelected)
        guard case let .alert(alert, _) = event else {
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
        let viewModel = addViewModel
        viewModel.state.inputs[0].value.value = "name"
        viewModel.state.inputs[1].value.value = "http://example.com"
        viewModel.state.inputs[2].value.value = "password"

        var values = [Bool]()
        viewModel.state.isLoading.dropFirst().sink {
            values.append($0)
        }.store(in: &cancellables)

        viewModel.handle(.saveSelected)
        XCTAssertEqual(values, [true, false])
    }

    func test_saveSelected_shouldAuthenticate() {
        let viewModel = addViewModel
        viewModel.state.inputs[0].value.value = "name"
        viewModel.state.inputs[1].value.value = "http://example.com"
        viewModel.state.inputs[2].value.value = "password"
        viewModel.handle(.saveSelected)
        XCTAssertEqual(client.requestParamRequest.map(\.method), ["auth.login"])
    }

    func test_save_whenAuthenticationFails_shouldEmitError() {
        client.results.append((
            method: "auth.login",
            result: Fail(error: .unauthenticated).eraseToAnyPublisher()
        ))
        let viewModel = addViewModel
        viewModel.state.inputs[0].value.value = "name"
        viewModel.state.inputs[1].value.value = "http://example.com"
        viewModel.state.inputs[2].value.value = "password"

        var event: ServerSettingsEvent?
        viewModel.events.first().sink { event = $0 }.store(in: &cancellables)
        viewModel.handle(.saveSelected)
        guard case let .alert(alert, _) = event else {
            XCTFail("Unexpected event: \(String(describing: event))")
            return
        }
        XCTAssertEqual(alert.title, "Authentication Failed")
        XCTAssertEqual(alert.message, "Unable to authenticate. Verify that your credentials are correct.")
    }

    func test_saveSelected_withoutData_shouldDoNothing() {
        let viewModel = addViewModel
        let expectation = self.expectation(description: "Received value")
        expectation.isInverted = true
        viewModel.state.isLoading.dropFirst().sink { _ in
            expectation.fulfill()
        }.store(in: &cancellables)
        viewModel.handle(.saveSelected)
        waitForExpectations(timeout: 0)
    }

    func test_saveSelected_withoutServer_shouldAddServer() throws {
        client.results.append((
            method: "auth.login",
            result: Just(()).setFailureType(to: DelugeError.self).eraseToAnyPublisher()
        ))

        let settings = DelugeServerSettings(url: URL(string: "http://example.com")!)
        let keychain = DelugeKeychainData(password: "password")
        let expectedData = try JSONEncoder().encode(settings)
        let expectedKeychainData = try JSONEncoder().encode(keychain)

        let viewModel = addViewModel
        viewModel.state.inputs[0].value.value = "name"
        viewModel.state.inputs[1].value.value = settings.url.absoluteString
        viewModel.state.inputs[2].value.value = keychain.password
        viewModel.handle(.saveSelected)
        let server = preferences.getServers()[0]
        XCTAssertEqual(server.name, "name")
        XCTAssertEqual(server.data, expectedData)
        XCTAssertEqual(server.keychainData, expectedKeychainData)
    }

    func test_saveSelected_withServer_shouldUpdateServer() throws {
        client.results.append((
            method: "auth.login",
            result: Just(()).setFailureType(to: DelugeError.self).eraseToAnyPublisher()
        ))

        let settings = DelugeServerSettings(url: URL(string: "http://example.com/new")!)
        let keychain = DelugeKeychainData(password: "new-password")
        let expectedData = try JSONEncoder().encode(settings)
        let expectedKeychainData = try JSONEncoder().encode(keychain)

        let viewModel = editViewModel
        viewModel.state.inputs[0].value.value = "new name"
        viewModel.state.inputs[1].value.value = settings.url.absoluteString
        viewModel.state.inputs[2].value.value = keychain.password
        viewModel.handle(.saveSelected)
        let server = preferences.getServers()[0]
        XCTAssertEqual(server.name, "new name")
        XCTAssertEqual(server.data, expectedData)
        XCTAssertEqual(server.keychainData, expectedKeychainData)
    }

    func test_saveSelected_withoutServer_shouldEmitCompleteEvent() {
        client.results.append((
            method: "auth.login",
            result: Just(()).setFailureType(to: DelugeError.self).eraseToAnyPublisher()
        ))

        let viewModel = addViewModel
        viewModel.state.inputs[0].value.value = "name"
        viewModel.state.inputs[1].value.value = "http://example.com"
        viewModel.state.inputs[2].value.value = "password"

        var event: ServerSettingsEvent?
        viewModel.events.first().sink { event = $0 }.store(in: &cancellables)
        viewModel.handle(.saveSelected)
        guard case .complete = event else {
            XCTFail("Unexpected event: \(String(describing: event))")
            return
        }
    }

    func test_saveSelected_withServer_shouldEmitCompleteEvent() {
        client.results.append((
            method: "auth.login",
            result: Just(()).setFailureType(to: DelugeError.self).eraseToAnyPublisher()
        ))

        let viewModel = editViewModel
        var event: ServerSettingsEvent?
        viewModel.events.first().sink { event = $0 }.store(in: &cancellables)
        viewModel.handle(.saveSelected)
        guard case .complete = event else {
            XCTFail("Unexpected event: \(String(describing: event))")
            return
        }
    }

    func test_deleteSelected_withoutServer_shouldDoNothing() {
        let viewModel = addViewModel
        let expectation = self.expectation(description: "Value received")
        expectation.isInverted = true
        viewModel.events.first().sink { _ in
            expectation.fulfill()
        }.store(in: &cancellables)
        viewModel.handle(.deleteSelected(source: .view(UIView(), rect: .zero)))
        waitForExpectations(timeout: 0)
    }

    func test_deleteSelected_withServer_shouldEmitAlert() {
        let viewModel = editViewModel
        var event: ServerSettingsEvent?
        viewModel.events.first().sink { event = $0 }.store(in: &cancellables)
        viewModel.handle(.deleteSelected(source: .view(UIView(), rect: .zero)))
        guard case let .alert(alert, _) = event else {
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
        let viewModel = editViewModel
        var event: ServerSettingsEvent?
        viewModel.events.first().sink { event = $0 }.store(in: &cancellables)
        viewModel.handle(.deleteSelected(source: .view(UIView(), rect: .zero)))
        guard case let .alert(alert, _) = event else {
            XCTFail("Unexpected event: \(String(describing: event))")
            return
        }
        alert.actions.first { $0.title == "Delete Server" }?.handler?()
        XCTAssertTrue(preferences.getServers().isEmpty)
    }

    func test_deleteSelected_whenDeleteServerSelected_shouldEmitCompleteEvent() {
        preferences.addOrUpdate(server: server)
        let viewModel = editViewModel
        var event: ServerSettingsEvent?
        viewModel.events.first().sink { event = $0 }.store(in: &cancellables)
        viewModel.handle(.deleteSelected(source: .view(UIView(), rect: .zero)))
        guard case let .alert(alert, _) = event else {
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

private struct MockClientProvider: DelugeClientProvider {
    let client: DelugeClient

    func createClient(baseURL: URL, password: String) -> DelugeClient {
        return client
    }
}
