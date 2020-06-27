import Combine
@testable import Magnesium
import SnapshotTesting
import ViewModel
import XCTest

class ServerSettingsViewControllerTests: TestCase {
    func test_loading() {
        var values = ServerSettingsViewValues.editServer
        values.isLoading = Just(true).eraseToAnyPublisher()
        let viewModel = StaticViewModel(values: values, viewEvent: ServerSettingsViewEvent.self)
        let viewController = ServerSettingsViewController(viewModel: viewModel)
        let navigationController = UINavigationController(rootViewController: viewController)
        assertSnapshot(matching: navigationController, as: .image)
    }

    func test_addServer_withDeluge() {
        let viewModel = DelugeSettingsViewModel()
        let viewController = ServerSettingsViewController(viewModel: viewModel)
        let navigationController = UINavigationController(rootViewController: viewController)
        assertSnapshot(matching: navigationController, as: .image)
    }

    func test_editServer_withDeluge() {
        let viewModel = DelugeSettingsViewModel(server: .mock(.deluge))
        let viewController = ServerSettingsViewController(viewModel: viewModel)
        let navigationController = UINavigationController(rootViewController: viewController)
        assertSnapshot(matching: navigationController, as: .image)
    }

    func test_addServer_withTransmission() {
        let viewModel = TransmissionSettingsViewModel()
        let viewController = ServerSettingsViewController(viewModel: viewModel)
        let navigationController = UINavigationController(rootViewController: viewController)
        assertSnapshot(matching: navigationController, as: .image)
    }

    func test_editServer_withTransmission() {
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
