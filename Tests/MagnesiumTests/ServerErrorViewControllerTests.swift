@testable import Magnesium
import SnapshotTesting
import XCTest

class ServerErrorViewControllerTests: TestCase {
    func test_view() {
        let viewController = ServerErrorViewController(viewModel: ServerErrorViewModel())
        let navigationController = UINavigationController(rootViewController: viewController)
        assertSnapshot(matching: navigationController, as: .image)
    }
}
