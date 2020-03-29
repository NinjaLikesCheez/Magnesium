@testable import Magnesium
import SnapshotTesting
import XCTest

class FilterViewControllerTests: TestCase {
    func test_view() {
        let viewModel = FilterViewModel(labels: .init([MockLabel(), MockLabel(name: "label")]))
        let viewController = FilterViewController(viewModel: viewModel)
        let navigationController = UINavigationController(rootViewController: viewController)
        assertSnapshot(matching: navigationController, as: .image)
    }
}
