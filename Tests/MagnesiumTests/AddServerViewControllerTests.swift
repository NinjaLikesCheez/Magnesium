@testable import Magnesium
import SnapshotTesting
import ViewModel
import XCTest

class AddServerViewControllerTests: TestCase {
    func test_view() {
        let values = AddServerViewValues(types: [
            "Deluge",
            "Transmission",
        ])
        let viewModel = StaticViewModel(values: values, viewEvent: AddServerViewEvent.self)
        let viewController = AddServerViewController(viewModel: viewModel)
        let navigationController = UINavigationController(rootViewController: viewController)
        assertSnapshot(matching: navigationController, as: .image)
    }
}
