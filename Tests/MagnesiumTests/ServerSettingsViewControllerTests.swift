import Combine
@testable import Magnesium
import SnapshotTesting
import ViewModel
import XCTest

class ServerSettingsViewControllerTests: TestCase {
    func test_snapshot_whenLoading() {
        var values = ServerSettingsViewValues.editServer
        values.isLoading = Just(true).eraseToAnyPublisher()
        let viewModel = StaticViewModel(event: ServerSettingsViewEvent.self, values: values)
        let viewController = ServerSettingsViewController(viewModel: viewModel)
        let navigationController = UINavigationController(rootViewController: viewController)
        assertSnapshot(matching: navigationController, as: .image)
    }

    func test_snapshot_whenAddingDelugeServer() {
        let viewModel = DelugeSettingsViewModel()
        let viewController = ServerSettingsViewController(viewModel: viewModel)
        let navigationController = UINavigationController(rootViewController: viewController)
        assertSnapshot(matching: navigationController, as: .image)
    }

    func test_snapshot_whenEditingDelugeServer() {
        let viewModel = DelugeSettingsViewModel(server: .mock(.deluge))
        let viewController = ServerSettingsViewController(viewModel: viewModel)
        let navigationController = UINavigationController(rootViewController: viewController)
        assertSnapshot(matching: navigationController, as: .image)
    }

    func test_snapshot_whenAddingTransmissionServer() {
        let viewModel = TransmissionSettingsViewModel()
        let viewController = ServerSettingsViewController(viewModel: viewModel)
        let navigationController = UINavigationController(rootViewController: viewController)
        assertSnapshot(matching: navigationController, as: .image)
    }

    func test_snapshot_whenEditingTransmissionServer() {
        let viewModel = TransmissionSettingsViewModel(server: .mock(.transmission))
        let viewController = ServerSettingsViewController(viewModel: viewModel)
        let navigationController = UINavigationController(rootViewController: viewController)
        assertSnapshot(matching: navigationController, as: .image)
    }
}

private extension ServerSettingsViewValues {
    static var editServer: ServerSettingsViewValues {
        .init(
            title: "Edit Server",
            saveButtonTitle: "Save",
            canDelete: true,
            isLoading: Just(false).eraseToAnyPublisher(),
            isSaveButtonEnabled: Just(true).eraseToAnyPublisher(),
            inputs: [
                .init(
                    name: "server",
                    placeholder: "https://example.com",
                    value: .init("https://example.com"),
                    configuration: .url
                ),
                .init(
                    name: "password",
                    placeholder: "password",
                    value: .init("password"),
                    configuration: .password
                ),
            ]
        )
    }
}
