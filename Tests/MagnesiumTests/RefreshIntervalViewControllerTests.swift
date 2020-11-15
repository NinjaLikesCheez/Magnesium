import Combine
@testable import Magnesium
import SnapshotTesting
import ViewModel
import XCTest

class RefreshIntervalViewControllerTests: TestCase {
    func test_snapshot() {
        let values = RefreshIntervalViewValues(options: [
            .init(title: "2 seconds", isSelected: .init(true)),
            .init(title: "5 seconds", isSelected: .init(false)),
        ])
        let viewModel = StaticViewModel(event: RefreshIntervalViewEvent.self, values: values)
        let viewController = RefreshIntervalViewController(viewModel: viewModel)
        let navigationController = UINavigationController(rootViewController: viewController)
        assertSnapshot(matching: navigationController, as: .image)
    }
}
