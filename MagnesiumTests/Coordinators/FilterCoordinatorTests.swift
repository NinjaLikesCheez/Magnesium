import Combine
import CommonModels
@testable import Magnesium
import XCTest

class FilterCoordinatorTests: XCTestCase {
    private var window: UIWindow!
    private var coordinator: FilterCoordinator!

    override func setUp() {
        super.setUp()
        Current = .mock
        window = UIWindow()
        coordinator = FilterCoordinator(labels: CurrentValueSubject([]))

        // the view controller needs to be in a key window to perform a presentation
        window.rootViewController = coordinator.presentable.viewController
        window.makeKeyAndVisible()
    }

    func test_presentable_shouldBeNavigationController_withFilterViewController() {
        let navigationController = coordinator.presentable.viewController as! UINavigationController
        let viewController = navigationController.viewControllers[0]
        guard type(of: viewController) === FilterViewController<FilterViewModel>.self else {
            XCTFail("Unexpected view controller: \(String(describing: viewController))")
            return
        }
    }

    // MARK: handle - FilterEvent

    func test_filterEvent_complete_shouldEmitCompleteEvent() throws {
        let event = try coordinator.events.wait().first {
            self.coordinator.receive(.complete)
        }.unwrap()
        XCTAssertEqual(event, .complete)
    }

    func test_settingsEvent_alert_shouldPresentAlertController() {
        coordinator.receive(.alert(Alert(title: "", style: .alert)))
        let viewController = coordinator.presentable.viewController
        guard type(of: viewController.presentedViewController!) === UIAlertController.self else {
            XCTFail("Unexpected view controller: \(String(describing: viewController))")
            return
        }
    }
}
