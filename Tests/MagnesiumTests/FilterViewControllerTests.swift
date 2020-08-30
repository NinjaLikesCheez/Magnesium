import Combine
@testable import Magnesium
import SnapshotTesting
import XCTest

class FilterViewControllerTests: TestCase {
    func test_snapshot() {
        let viewModel = FilterViewModel(labels: Just([.mock(), .mock(name: "label")]).eraseToAnyPublisher())
        let viewController = FilterViewController(viewModel: viewModel)
        let navigationController = UINavigationController(rootViewController: viewController)
        assertSnapshot(matching: navigationController, as: .image)
    }
}
