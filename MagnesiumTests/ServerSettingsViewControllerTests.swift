import Combine
@testable import Magnesium
import SnapshotTesting
import ViewModel
import XCTest

class ServerSettingsViewControllerTests: TestCase {
    func test_addServer() {
        let viewRep = ServerSettingsViewRepresentation(
            title: "Add Server",
            saveButtonTitle: "Add",
            canDelete: false,
            isLoading: Just(false).eraseToAnyPublisher(),
            isSaveButtonEnabled: Just(false).eraseToAnyPublisher(),
            inputs: [
                .init(
                    name: "server",
                    placeholder: "https://example.com",
                    value: .init(nil),
                    configuration: .url
                ),
                .init(
                    name: "password",
                    placeholder: "password",
                    value: .init(nil),
                    configuration: .password
                ),
            ]
        )
        let viewModel = StaticViewModel(view: viewRep, type: ServerSettingsViewEvent.self)
        let viewController = ServerSettingsViewController(viewModel: viewModel)
        let navigationController = UINavigationController(rootViewController: viewController)
        assertSnapshot(matching: navigationController, as: .image)
    }

    func test_editServer() {
        let viewRep = ServerSettingsViewRepresentation.editServer
        let viewModel = StaticViewModel(view: viewRep, type: ServerSettingsViewEvent.self)
        let viewController = ServerSettingsViewController(viewModel: viewModel)
        let navigationController = UINavigationController(rootViewController: viewController)
        assertSnapshot(matching: navigationController, as: .image)
    }

    func test_whenLoading() {
        var viewRep = ServerSettingsViewRepresentation.editServer
        viewRep.isLoading = Just(true).eraseToAnyPublisher()
        let viewModel = StaticViewModel(view: viewRep, type: ServerSettingsViewEvent.self)
        let viewController = ServerSettingsViewController(viewModel: viewModel)
        let navigationController = UINavigationController(rootViewController: viewController)
        assertSnapshot(matching: navigationController, as: .image)
    }
}

private extension ServerSettingsViewRepresentation {
    static var editServer: ServerSettingsViewRepresentation {
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
