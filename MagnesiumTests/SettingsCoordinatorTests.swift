import Combine
import CommonModels
import Coordinator
@testable import Magnesium
import Preferences
import XCTest

class SettingsCoordinatorTests: TestCase {
    private var window: UIWindow!
    private var session: Session!
    private var coordinator: SettingsCoordinator!
    private var preferences: Preferences { Current.preferences }

    override func setUp() {
        super.setUp()
        window = UIWindow()
        session = Session()
        coordinator = SettingsCoordinator(session: session)

        // the view controller needs to be in a key window to perform a presentation
        window.rootViewController = coordinator.presentable.viewController
        window.makeKeyAndVisible()
    }

    func test_presentable_shouldBeNavigationController_withSettingsViewController() {
        let navigationController = coordinator.presentable.viewController as! UINavigationController
        XCTAssertType(navigationController.viewControllers.first, SettingsViewController<SettingsViewModel>.self)
    }

    // MARK: - SettingsEvent

    func test_settingsEvent_complete_shouldEmitCompleteEvent() throws {
        let event = try coordinator.eventPublisher.first().wait {
            self.coordinator.send(.complete)
        }.singleValue()
        XCTAssertEqual(event, .complete)
    }

    func test_settingsEvent_alert_shouldPresentAlertController() {
        coordinator.send(.alert(Alert(title: "", style: .alert)))
        let viewController = coordinator.presentable.viewController
        XCTAssertType(viewController.presentedViewController, UIAlertController.self)
    }

    func test_settingsEvent_editServer_withTransmissionServer_shouldPushServerSettingsViewController() {
        coordinator.send(.editServer(.mock(.transmission)))
        RunLoop.main.run(until: Date())
        let navigationController = coordinator.presentable.viewController as! UINavigationController
        let viewController = navigationController.viewControllers[1]
        XCTAssertType(viewController, ServerSettingsViewController<AnyServerSettingsViewModel>.self)
    }

    func test_settingsEvent_editServer_withDelugeServer_shouldPushServerSettingsViewController() {
        coordinator.send(.editServer(.mock(.deluge)))
        RunLoop.main.run(until: Date())
        let navigationController = coordinator.presentable.viewController as! UINavigationController
        let viewController = navigationController.viewControllers[1]
        XCTAssertType(viewController, ServerSettingsViewController<AnyServerSettingsViewModel>.self)
    }

    func test_settingsEvent_addServer_shouldPushAddServerViewController() {
        coordinator.send(.addServer)
        RunLoop.main.run(until: Date())
        let navigationController = coordinator.presentable.viewController as! UINavigationController
        let viewController = navigationController.viewControllers[1]
        XCTAssertType(viewController, AddServerViewController<AddServerViewModel>.self)
    }

    func test_settingsEvent_showRefreshIntervalSettings_shouldPushRefreshIntervalViewController() {
        coordinator.send(.showRefreshIntervalSettings)
        RunLoop.main.run(until: Date())
        let navigationController = coordinator.presentable.viewController as! UINavigationController
        let viewController = navigationController.viewControllers[1]
        XCTAssertType(viewController, RefreshIntervalViewController<RefreshIntervalViewModel>.self)
    }

    // MARK: - ServerSettingsCoordinatorEvent

    func test_serverSettingsCoordinatorEvent_complete_shouldPopViewController() {
        let navigationController = coordinator.presentable.viewController as! UINavigationController

        coordinator.send(.editServer(.mock(.transmission)))
        RunLoop.main.run(until: Date())
        XCTAssertEqual(navigationController.viewControllers.count, 2)

        let coordinator = MockCoordinator(
            viewController: navigationController.viewControllers[1] as! PresentableTableViewController
        )
        self.coordinator.handle(ServerSettingsCoordinatorEvent.complete, from: coordinator)
        RunLoop.main.run(until: Date())
        XCTAssertEqual(navigationController.viewControllers.count, 1)
    }

    // MARK: - AddServerCoordinatorEvent

    func test_addServerCoordinatorEvent_completeEvent_shouldPopRootViewController() {
        let navigationController = coordinator.presentable.viewController as! UINavigationController

        coordinator.send(.editServer(.mock(.transmission)))
        RunLoop.main.run(until: Date())
        navigationController.pushViewController(UIViewController(), animated: false)
        XCTAssertEqual(navigationController.viewControllers.count, 3)

        let coordinator = MockCoordinator(
            viewController: navigationController.viewControllers[1] as! PresentableTableViewController
        )
        self.coordinator.handle(AddServerCoordinatorEvent.complete, from: coordinator)
        RunLoop.main.run(until: Date())
        XCTAssertEqual(navigationController.viewControllers.count, 1)
    }
}
