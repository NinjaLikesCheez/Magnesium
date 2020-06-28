import Combine
import CommonModels
@testable import Magnesium
import XCTest

class FilterCoordinatorTests: TestCase {
    private var coordinator: FilterCoordinator!

    override func setUp() {
        super.setUp()
        coordinator = FilterCoordinator(labels: Just([]).eraseToAnyPublisher())
    }

    func test_presentable_shouldBeNavigationController_withFilterViewController() {
        let navigationController = coordinator.presentable.viewController as! UINavigationController
        XCTAssertType(navigationController.viewControllers.first, FilterViewController<FilterViewModel>.self)
    }

    // MARK: handle - FilterEvent

    func test_filterEvent_complete_shouldEmitCompleteEvent() throws {
        let event = try coordinator.eventPublisher.first().wait {
            self.coordinator.send(.complete)
        }.singleValue()
        XCTAssertEqual(event, .complete)
    }
}
