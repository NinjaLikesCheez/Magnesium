import Combine
import CommonModels
@testable import Magnesium
import XCTest

class FilterCoordinatorTests: TestCase {
    private var window: UIWindow!
    private var coordinator: FilterCoordinator!

    override func setUp() {
        super.setUp()
        window = UIWindow()
        coordinator = FilterCoordinator(labels: Just([]).eraseToAnyPublisher())

        // the view controller needs to be in a key window to perform a presentation
        window.rootViewController = coordinator.presentable.viewController
        window.makeKeyAndVisible()
    }

    func test_presentable_shouldBeNavigationController_withFilterViewController() {
        let navigationController = coordinator.presentable.viewController as! UINavigationController
        XCTAssertType(navigationController.viewControllers.first, FilterViewController<FilterViewModel>.self)
    }

    // MARK: handle - FilterEvent

    func test_filterEvent_complete_shouldEmitCompleteEvent() throws {
        let event = try coordinator.eventPublisher.first().wait {
            self.coordinator.send(.complete)
        }.value()
        XCTAssertEqual(event, .complete)
    }

    func test_settingsEvent_alert_shouldPresentAlertController() {
        coordinator.send(.alert(Alert(title: "", style: .alert)))
        let viewController = coordinator.presentable.viewController
        XCTAssertType(viewController.presentedViewController, UIAlertController.self)
    }
}
