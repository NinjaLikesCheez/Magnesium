import Combine
@testable import Magnesium
import SnapshotTesting
import ViewModel
import XCTest

class SettingsViewControllerTests: TestCase {
    func test_view() {
        let values = SettingsViewValues(
            sections: Just([
                .init(type: .changeServer, items: [.changeServer("Server 1")]),
                .init(type: .servers, items: [.server(id: 0, name: "Server 1"), .server(id: 1, name: "Server 2")]),
                .init(type: .general, items: [.refreshInterval(current: "2 seconds")]),
            ]).eraseToAnyPublisher()
        )
        let viewModel = StaticViewModel(event: SettingsViewEvent.self, values: values)
        let viewController = SettingsViewController(viewModel: viewModel)
        let navigationController = UINavigationController(rootViewController: viewController)
        assertSnapshot(matching: navigationController, as: .image)
    }
}
