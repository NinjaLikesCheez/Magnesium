@testable import Magnesium
import SnapshotTesting
import ViewModel
import XCTest

class AddServerViewControllerTests: TestCase {
    func test_view() {
        let viewRep = AddServerViewRepresentation(types: [
            "Deluge",
            "Transmission",
        ])
        let viewModel = StaticViewModel(view: viewRep, type: AddServerViewEvent.self)
        let viewController = AddServerViewController(viewModel: viewModel)
        let navigationController = UINavigationController(rootViewController: viewController)
        assertSnapshot(matching: navigationController, as: .image)
    }
}
