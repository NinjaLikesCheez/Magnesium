@testable import Magnesium
import SnapshotTesting
import XCTest

class AddServerViewControllerTests: XCTestCase {
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
