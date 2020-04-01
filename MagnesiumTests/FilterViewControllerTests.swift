import Combine
@testable import Magnesium
import SnapshotTesting
import XCTest

class FilterViewControllerTests: TestCase {
    func test_view() {
        let viewModel = FilterViewModel(labels: Just([MockLabel(), MockLabel(name: "label")]).eraseToAnyPublisher())
        let viewController = FilterViewController(viewModel: viewModel)
        let navigationController = UINavigationController(rootViewController: viewController)
        assertSnapshot(matching: navigationController, as: .image)
    }
}
