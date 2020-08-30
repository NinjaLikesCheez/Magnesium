@testable import Magnesium
import SnapshotTesting
import ViewModel
import XCTest

class AddServerViewControllerTests: TestCase {
    func test_snapshot() {
        let values = AddServerViewValues(types: [
            "Deluge",
            "Transmission",
        ])
        let viewModel = StaticViewModel(event: AddServerViewEvent.self, values: values)
        let viewController = AddServerViewController(viewModel: viewModel)
        let navigationController = UINavigationController(rootViewController: viewController)
        assertSnapshot(matching: navigationController, as: .image)
    }
}
