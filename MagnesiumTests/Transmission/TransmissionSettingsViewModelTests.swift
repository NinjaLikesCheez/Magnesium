import Combine
import CommonModels
@testable import Magnesium
import Preferences
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
        XCTAssertEqual(addViewModel.view.inputs.map(\.name), ["name", "server", "username", "password"])
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

    func test_isSaveButtonEnabled_withInvalidServer_shouldBeFalse() throws {
        let viewModel = addViewModel!
        viewModel.view.inputs[0].value.value = "name"
        viewModel.view.inputs[1].value.value = "web://site"

        let event = try viewModel.events.first().wait {
            viewModel.receive(.saveSelected)
        }.value()
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
        viewModel.view.inputs[0].value.value = "name"
        viewModel.view.inputs[1].value.value = "http://example.com"

        let values = viewModel.view.isLoading.dropFirst().wait {
            viewModel.receive(.saveSelected)
        }
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

    func test_saveSelected_whenAuthenticationFails_shouldEmitError() throws {
        client.results.append((
            "session-get",
            Fail(error: .unauthenticated).eraseToAnyPublisher()
        ))

        let viewModel = addViewModel!
        viewModel.view.inputs[0].value.value = "name"
        viewModel.view.inputs[1].value.value = "http://example.com"

        let event = try viewModel.events.first().wait {
            viewModel.receive(.saveSelected)
        }.value()
        let alert = try extract(case: type(of: event).alert, from: event)
        XCTAssertEqual(alert.title, "Authentication Failed")
        XCTAssertEqual(alert.message, "Unable to authenticate. Verify that your credentials are correct.")
    }

    func test_saveSelected_withoutData_shouldDoNothing() {
        let viewModel = addViewModel!
        let event = viewModel.view.isLoading.dropFirst().first().wait {
            viewModel.receive(.saveSelected)
        }
        XCTAssertFalse(event.hasValue())
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

    func test_saveSelected_withoutServer_shouldEmitCompleteEvent() throws {
        client.results.append((
            method: "session-get",
            result: Just(-1).setFailureType(to: TransmissionError.self).eraseToAnyPublisher()
        ))

        let viewModel = addViewModel!
        viewModel.view.inputs[0].value.value = "name"
        viewModel.view.inputs[1].value.value = "http://example.com"
        viewModel.view.inputs[2].value.value = "password"

        let event = try viewModel.events.first().wait {
            viewModel.receive(.saveSelected)
        }.value()
        XCTAssertCase(event, .complete)
    }

    func test_saveSelected_withServer_shouldEmitCompleteEvent() throws {
        client.results.append((
            method: "session-get",
            result: Just(-1).setFailureType(to: TransmissionError.self).eraseToAnyPublisher()
        ))

        let viewModel = editViewModel!
        let event = try viewModel.events.first().wait {
            viewModel.receive(.saveSelected)
        }.value()
        XCTAssertCase(event, .complete)
    }

    func test_deleteSelected_withoutServer_shouldDoNothing() {
        let viewModel = addViewModel!
        let event = viewModel.events.first().wait {
            viewModel.receive(.deleteSelected(source: .view(UIView(), rect: .zero)))
        }
        XCTAssertFalse(event.hasValue())
    }

    func test_deleteSelected_withServer_shouldEmitAlert() throws {
        let viewModel = editViewModel!
        let event = try viewModel.events.first().wait {
            viewModel.receive(.deleteSelected(source: .view(UIView(), rect: .zero)))
        }.value()
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
        let event = try viewModel.events.first().wait {
            viewModel.receive(.deleteSelected(source: .view(UIView(), rect: .zero)))
        }.value()
        let alert = try extract(case: type(of: event).alert, from: event)
        alert.actions.first { $0.title == "Delete Server" }?.handler?()
        XCTAssertTrue(preferences.getServers().isEmpty)
    }

    func test_deleteSelected_whenDeleteServerSelected_shouldEmitCompleteEvent() throws {
        preferences.addOrUpdate(server: server)
        let viewModel = editViewModel!

        let alertEvent = try viewModel.events.first().wait {
            viewModel.receive(.deleteSelected(source: .view(UIView(), rect: .zero)))
        }.value()
        let alert = try extract(case: type(of: alertEvent).alert, from: alertEvent)

        let event = try viewModel.events.first().wait {
            alert.actions.first { $0.title == "Delete Server" }?.handler?()
        }.value()
        XCTAssertCase(event, .complete)
        XCTAssertTrue(preferences.getServers().isEmpty)
    }
}
