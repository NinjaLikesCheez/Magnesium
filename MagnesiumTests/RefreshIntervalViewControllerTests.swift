import Combine
@testable import Magnesium
import SnapshotTesting
import ViewModel
import XCTest

class RefreshIntervalViewControllerTests: TestCase {
    func test_view() {
        let values = RefreshIntervalViewValues(options: [
            .init(title: "2 seconds", isSelected: Just(true).eraseToAnyPublisher()),
            .init(title: "5 seconds", isSelected: Just(false).eraseToAnyPublisher()),
        ])
        let viewModel = StaticViewModel(values: values, type: RefreshIntervalViewEvent.self)
        let viewController = RefreshIntervalViewController(viewModel: viewModel)
        let navigationController = UINavigationController(rootViewController: viewController)
        assertSnapshot(matching: navigationController, as: .image)
    }
}
