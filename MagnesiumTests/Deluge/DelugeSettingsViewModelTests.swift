import Combine
import CommonModels
import Deluge
@testable import Magnesium
import Preferences
import SnapshotTesting
import XCTest

class DelugeSettingsViewModelTests: TestCase {
    private var client: MockDelugeClient!
    private var addViewModel: DelugeSettingsViewModel!
    private var server: Server!
    private var editViewModel: DelugeSettingsViewModel!
    private var preferences: Preferences { Current.preferences }

    override func setUp() {
        super.setUp()
        client = MockDelugeClient()
        Current.deluge = { _, _ in self.client }
        addViewModel = DelugeSettingsViewModel()
        server = .mock(.deluge)
        editViewModel = DelugeSettingsViewModel(server: server)
    }

    func test_inputs() {
        XCTAssertEqual(addViewModel.values.inputs.map(\.name), ["name", "server", "password"])
    }

    func test_name_withServer_shouldUseExisting() {
        XCTAssertEqual(editViewModel.values.inputs[0].value.value, "MockServer")
    }

    func test_serverURL_withServer_shouldUseExisting() {
        XCTAssertEqual(editViewModel.values.inputs[1].value.value, "http://mock.mock")
    }

    func test_password_withServer_shouldUseExisting() {
        XCTAssertEqual(editViewModel.values.inputs[2].value.value, "mockpassword")
    }

    func test_title_withoutServer() {
        XCTAssertEqual(addViewModel.values.title, "Add Server")
    }

    func test_title_withServer() {
        XCTAssertEqual(editViewModel.values.title, "Edit Server")
    }

    func test_saveButtonTitle_withoutServer() {
        XCTAssertEqual(addViewModel.values.saveButtonTitle, "Add")
    }

    func test_saveButtonTitle_withServer() {
        XCTAssertEqual(editViewModel.values.saveButtonTitle, "Save")
    }

    func test_canDelete_withoutServer() {
        XCTAssertFalse(addViewModel.values.canDelete)
    }

    func test_canDelete_withServer() {
        XCTAssertTrue(editViewModel.values.canDelete)
    }

    private func isSaveButtonEnabled(_ viewModel: DelugeSettingsViewModel) -> Bool {
        var value: Bool!
        _ = viewModel.values.isSaveButtonEnabled.sink {
            value = $0
        }
        return value
    }

    func test_isSaveButtonEnabled_withValidData_shouldBeTrue() {
        let viewModel = addViewModel!
        XCTAssertFalse(isSaveButtonEnabled(viewModel))
        viewModel.values.inputs[0].value.value = "name"
        XCTAssertFalse(isSaveButtonEnabled(viewModel))
        viewModel.values.inputs[1].value.value = "http://example.com"
        XCTAssertFalse(isSaveButtonEnabled(viewModel))
        viewModel.values.inputs[2].value.value = "password"
        XCTAssertTrue(isSaveButtonEnabled(viewModel))
    }

    func test_saveSelected_withInvalidServer_shouldEmitAlert() throws {
        let viewModel = addViewModel!
        viewModel.values.inputs[0].value.value = "name"
        viewModel.values.inputs[1].value.value = "web://site"
        viewModel.values.inputs[2].value.value = "password"

        let event = try viewModel.eventPublisher.first().wait {
            viewModel.send(.saveSelected)
        }.singleValue()
        let alert = try extract(case: type(of: event).alert, from: event)
        XCTAssertEqual(alert.title, "Unable to Add Server")
        XCTAssertEqual(
            alert.message,
            "The server URL is invalid. Ensure the URL begins with \"http://\" or \"https://\"."
        )
        XCTAssertEqual(alert.actions.map(\.title), ["OK"])
    }

    func test_saveSelected_shouldChangeIsLoading() {
        let viewModel = addViewModel!
        viewModel.values.inputs[0].value.value = "name"
        viewModel.values.inputs[1].value.value = "http://example.com"
        viewModel.values.inputs[2].value.value = "password"

        let values = viewModel.values.isLoading.dropFirst().wait {
            viewModel.send(.saveSelected)
        }
        XCTAssertEqual(values, [true, false])
    }

    func test_saveSelected_shouldAuthenticate() {
        let viewModel = addViewModel!
        viewModel.values.inputs[0].value.value = "name"
        viewModel.values.inputs[1].value.value = "http://example.com"
        viewModel.values.inputs[2].value.value = "password"
        viewModel.send(.saveSelected)
        assertSnapshot(matching: client.requests, as: .requests)
    }

    func test_save_whenAuthenticationFails_shouldEmitError() throws {
        client.results.append((
            method: "auth.login",
            result: Fail(error: .unauthenticated).eraseToAnyPublisher()
        ))
        let viewModel = addViewModel!
        viewModel.values.inputs[0].value.value = "name"
        viewModel.values.inputs[1].value.value = "http://example.com"
        viewModel.values.inputs[2].value.value = "password"

        let event = try viewModel.eventPublisher.first().wait {
            viewModel.send(.saveSelected)
        }.singleValue()
        let alert = try extract(case: type(of: event).alert, from: event)
        XCTAssertEqual(alert.title, "Authentication Failed")
        XCTAssertEqual(alert.message, "Unable to authenticate. Verify that your credentials are correct.")
    }

    func test_saveSelected_withoutData_shouldDoNothing() {
        let viewModel = addViewModel!
        let event = viewModel.values.isLoading.dropFirst().first().wait {
            viewModel.send(.saveSelected)
        }
        XCTAssertTrue(event.values().isEmpty)
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

        let viewModel = addViewModel!
        viewModel.values.inputs[0].value.value = "name"
        viewModel.values.inputs[1].value.value = settings.url.absoluteString
        viewModel.values.inputs[2].value.value = keychain.password
        viewModel.send(.saveSelected)
        let server = try preferences.getServers()[0]
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

        let viewModel = editViewModel!
        viewModel.values.inputs[0].value.value = "new name"
        viewModel.values.inputs[1].value.value = settings.url.absoluteString
        viewModel.values.inputs[2].value.value = keychain.password
        viewModel.send(.saveSelected)
        let server = try preferences.getServers()[0]
        XCTAssertEqual(server.name, "new name")
        XCTAssertEqual(server.data, expectedData)
        XCTAssertEqual(server.keychainData, expectedKeychainData)
    }

    func test_saveSelected_withoutServer_shouldEmitCompleteEvent() throws {
        client.results.append((
            method: "auth.login",
            result: Just(()).setFailureType(to: DelugeError.self).eraseToAnyPublisher()
        ))

        let viewModel = addViewModel!
        viewModel.values.inputs[0].value.value = "name"
        viewModel.values.inputs[1].value.value = "http://example.com"
        viewModel.values.inputs[2].value.value = "password"

        let event = try viewModel.eventPublisher.first().wait {
            viewModel.send(.saveSelected)
        }.singleValue()
        XCTAssertCase(event, .complete)
    }

    func test_saveSelected_withServer_shouldEmitCompleteEvent() throws {
        client.results.append((
            method: "auth.login",
            result: Just(()).setFailureType(to: DelugeError.self).eraseToAnyPublisher()
        ))

        let viewModel = editViewModel!
        let event = try viewModel.eventPublisher.first().wait {
            viewModel.send(.saveSelected)
        }.singleValue()
        XCTAssertCase(event, .complete)
    }

    func test_deleteSelected_withoutServer_shouldDoNothing() {
        let viewModel = addViewModel!
        let event = viewModel.eventPublisher.first().wait {
            viewModel.send(.deleteSelected(source: .view(UIView(), rect: .zero)))
        }
        XCTAssertTrue(event.values().isEmpty)
    }

    func test_deleteSelected_withServer_shouldEmitAlert() throws {
        let viewModel = editViewModel!
        let event = try viewModel.eventPublisher.first().wait {
            viewModel.send(.deleteSelected(source: .view(UIView(), rect: .zero)))
        }.singleValue()
        let alert = try extract(case: type(of: event).alert, from: event)
        XCTAssertNil(alert.title)
        XCTAssertEqual(alert.message, "Are you sure you want to delete this server?")
        XCTAssertEqual(alert.actions[0].title, "Delete Server")
        XCTAssertEqual(alert.actions[0].style, AlertAction.Style.destructive)
        XCTAssertEqual(alert.actions[1].title, "Cancel")
    }

    func test_deleteSelected_whenDeleteServerSelected_shouldRemoveServer() throws {
        try preferences.addOrUpdate(server: server)
        let viewModel = editViewModel!
        let event = try viewModel.eventPublisher.first().wait {
            viewModel.send(.deleteSelected(source: .view(UIView(), rect: .zero)))
        }.singleValue()
        let alert = try extract(case: type(of: event).alert, from: event)
        alert.actions.first { $0.title == "Delete Server" }?.handler?()
        XCTAssertTrue(try preferences.getServers().isEmpty)
    }

    func test_deleteSelected_whenDeleteServerSelected_shouldEmitCompleteEvent() throws {
        try preferences.addOrUpdate(server: server)
        let viewModel = editViewModel!
        let alertEvent = try viewModel.eventPublisher.first().wait {
            viewModel.send(.deleteSelected(source: .view(UIView(), rect: .zero)))
        }.singleValue()
        let alert = try extract(case: type(of: alertEvent).alert, from: alertEvent)

        let event = try viewModel.eventPublisher.first().wait {
            alert.actions.first { $0.title == "Delete Server" }?.handler?()
        }.singleValue()
        XCTAssertCase(event, .complete)
        XCTAssertTrue(try preferences.getServers().isEmpty)
    }
}
