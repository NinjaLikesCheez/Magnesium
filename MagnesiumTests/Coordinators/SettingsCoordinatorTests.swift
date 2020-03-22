import Combine
import CommonModels
import Coordinator
@testable import Magnesium
import Preferences
import XCTest

class SettingsCoordinatorTests: XCTestCase {
    private var window: UIWindow!
    private var session: Session!
    private var coordinator: SettingsCoordinator!
    private var cancellables: Set<AnyCancellable>!
    private var preferences: Preferences { Current.preferences }

    override func setUp() {
        super.setUp()
        Current = .mock
        window = UIWindow()
        session = Session()
        coordinator = SettingsCoordinator(session: session)
        cancellables = Set()

        // the view controller needs to be in a key window to perform a presentation
        window.rootViewController = coordinator.presentable.viewController
        window.makeKeyAndVisible()
    }

    func test_presentable_shouldBeNavigationController_withSettingsViewController() {
        let navigationController = coordinator.presentable.viewController as! UINavigationController
        let viewController = navigationController.viewControllers[0]
        guard type(of: viewController) === SettingsViewController<SettingsViewModel>.self else {
            XCTFail("Unexpected view controller: \(String(describing: viewController))")
            return
        }
    }

    // MARK: - SettingsEvent

    func test_settingsEvent_complete_shouldEmitCompleteEvent() {
        let event = coordinator.events.wait().first {
            self.coordinator.receive(.complete)
        }
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

    func test_settingsEvent_editServer_withTransmissionServer_shouldPushServerSettingsViewController() {
        coordinator.receive(.editServer(.mock(.transmission)))
        RunLoop.main.run(until: Date())
        let navigationController = coordinator.presentable.viewController as! UINavigationController
        let viewController = navigationController.viewControllers[1]
        guard type(of: viewController) === ServerSettingsViewController<AnyServerSettingsViewModel>.self else {
            XCTFail("Unexpected view controller: \(String(describing: viewController))")
            return
        }
    }

    func test_settingsEvent_editServer_withDelugeServer_shouldPushServerSettingsViewController() {
        coordinator.receive(.editServer(.mock(.deluge)))
        RunLoop.main.run(until: Date())
        let navigationController = coordinator.presentable.viewController as! UINavigationController
        let viewController = navigationController.viewControllers[1]
        guard type(of: viewController) === ServerSettingsViewController<AnyServerSettingsViewModel>.self else {
            XCTFail("Unexpected view controller: \(String(describing: viewController))")
            return
        }
    }

    func test_settingsEvent_addServer_shouldPushAddServerViewController() {
        coordinator.receive(.addServer)
        RunLoop.main.run(until: Date())
        let navigationController = coordinator.presentable.viewController as! UINavigationController
        let viewController = navigationController.viewControllers[1]
        guard type(of: viewController) === AddServerViewController<AddServerViewModel>.self else {
            XCTFail("Unexpected view controller: \(String(describing: viewController))")
            return
        }
    }

    func test_settingsEvent_showRefreshIntervalSettings_shouldPushRefreshIntervalViewController() {
        coordinator.receive(.showRefreshIntervalSettings)
        RunLoop.main.run(until: Date())
        let navigationController = coordinator.presentable.viewController as! UINavigationController
        let viewController = navigationController.viewControllers[1]
        guard type(of: viewController) === RefreshIntervalViewController<RefreshIntervalViewModel>.self else {
            XCTFail("Unexpected view controller: \(String(describing: viewController))")
            return
        }
    }

    // MARK: - ServerSettingsCoordinatorEvent

    func test_serverSettingsCoordinatorEvent_complete_shouldPopViewController() {
        let navigationController = coordinator.presentable.viewController as! UINavigationController

        coordinator.receive(.editServer(.mock(.transmission)))
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

        coordinator.receive(.editServer(.mock(.transmission)))
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
