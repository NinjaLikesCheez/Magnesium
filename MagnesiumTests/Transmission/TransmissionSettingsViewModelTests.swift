import Combine
import CommonModels
@testable import Magnesium
import Preferences
import SnapshotTesting
import Transmission
import XCTest

class TransmissionSettingsViewModelTests: TestCase {
    private var client: MockTransmissionClient!
    private var addViewModel: TransmissionSettingsViewModel!
    private var server: Server!
    private var editViewModel: TransmissionSettingsViewModel!
    private var preferences: Preferences { Current.preferences }

    override func setUp() {
        super.setUp()
        client = MockTransmissionClient()
        Current.transmission = { _, _, _ in self.client }
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
    }

    func test_inputs() {
        XCTAssertEqual(addViewModel.values.inputs.map(\.name), ["name", "server", "username", "password"])
    }

    func test_name_withServer_shouldUseExisting() {
        XCTAssertEqual(editViewModel.values.inputs[0].value.value, "Server")
    }

    func test_serverURL_withServer_shouldUseExisting() {
        XCTAssertEqual(editViewModel.values.inputs[1].value.value, "http://example.com")
    }

    func test_username_withServer_shouldUseExisting() {
        XCTAssertEqual(editViewModel.values.inputs[2].value.value, "username")
    }

    func test_password_withServer_shouldUseExisting() {
        XCTAssertEqual(editViewModel.values.inputs[3].value.value, "password")
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

    private func isSaveButtonEnabled(_ viewModel: TransmissionSettingsViewModel) -> Bool {
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
        XCTAssertTrue(isSaveButtonEnabled(viewModel))
    }

    func test_isSaveButtonEnabled_withInvalidServer_shouldBeFalse() throws {
        let viewModel = addViewModel!
        viewModel.values.inputs[0].value.value = "name"
        viewModel.values.inputs[1].value.value = "web://site"

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

        let values = viewModel.values.isLoading.dropFirst().wait {
            viewModel.send(.saveSelected)
        }
        XCTAssertEqual(values, [true, false])
    }

    func test_saveSelected_shouldRequestRPCVersion() {
        let viewModel = addViewModel!
        viewModel.values.inputs[0].value.value = "name"
        viewModel.values.inputs[1].value.value = "http://example.com"
        viewModel.send(.saveSelected)
        assertSnapshot(matching: client.requests, as: .requests)
    }

    func test_saveSelected_whenAuthenticationFails_shouldEmitError() throws {
        client.results.append((
            "session-get",
            Fail(error: .unauthenticated).eraseToAnyPublisher()
        ))

        let viewModel = addViewModel!
        viewModel.values.inputs[0].value.value = "name"
        viewModel.values.inputs[1].value.value = "http://example.com"

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
            method: "session-get",
            result: Just(-1).setFailureType(to: TransmissionError.self).eraseToAnyPublisher()
        ))

        let settings = TransmissionServerSettings(url: URL(string: "http://example.com")!, username: "username")
        let keychain = TransmissionKeychainData(password: "password")
        let expectedData = try JSONEncoder().encode(settings)
        let expectedKeychainData = try JSONEncoder().encode(keychain)

        let viewModel = addViewModel!
        viewModel.values.inputs[0].value.value = "name"
        viewModel.values.inputs[1].value.value = settings.url.absoluteString
        viewModel.values.inputs[2].value.value = settings.username
        viewModel.values.inputs[3].value.value = keychain.password
        viewModel.send(.saveSelected)
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
        viewModel.values.inputs[0].value.value = "new name"
        viewModel.values.inputs[1].value.value = settings.url.absoluteString
        viewModel.values.inputs[2].value.value = settings.username
        viewModel.values.inputs[3].value.value = keychain.password
        viewModel.send(.saveSelected)
        let server = preferences.getServers()[0]
        XCTAssertEqual(server.name, "new name")
        XCTAssertEqual(server.data, expectedData)
        XCTAssertEqual(server.keychainData, expectedKeychainData)
    }

    func test_saveSelected_withoutServer_shouldEmitCompleteEvent() throws {
        client.results.append((
            method: "session-get",
            result: Just(-1).setFailureType(to: TransmissionError.self).eraseToAnyPublisher()
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
            method: "session-get",
            result: Just(-1).setFailureType(to: TransmissionError.self).eraseToAnyPublisher()
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
        preferences.addOrUpdate(server: server)
        let viewModel = editViewModel!
        let event = try viewModel.eventPublisher.first().wait {
            viewModel.send(.deleteSelected(source: .view(UIView(), rect: .zero)))
        }.singleValue()
        let alert = try extract(case: type(of: event).alert, from: event)
        alert.actions.first { $0.title == "Delete Server" }?.handler?()
        XCTAssertTrue(preferences.getServers().isEmpty)
    }

    func test_deleteSelected_whenDeleteServerSelected_shouldEmitCompleteEvent() throws {
        preferences.addOrUpdate(server: server)
        let viewModel = editViewModel!

        let alertEvent = try viewModel.eventPublisher.first().wait {
            viewModel.send(.deleteSelected(source: .view(UIView(), rect: .zero)))
        }.singleValue()
        let alert = try extract(case: type(of: alertEvent).alert, from: alertEvent)

        let event = try viewModel.eventPublisher.first().wait {
            alert.actions.first { $0.title == "Delete Server" }?.handler?()
        }.singleValue()
        XCTAssertCase(event, .complete)
        XCTAssertTrue(preferences.getServers().isEmpty)
    }
}
