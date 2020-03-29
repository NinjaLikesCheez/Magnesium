@testable import Magnesium
import SnapshotTesting
import XCTest

class NoServersViewControllerTests: XCTestCase {
    func test_view() {
        let viewController = NoServersViewController(viewModel: NoServersViewModel())
        let navigationController = UINavigationController(rootViewController: viewController)
        assertSnapshot(matching: navigationController, as: .image)
    }
}
