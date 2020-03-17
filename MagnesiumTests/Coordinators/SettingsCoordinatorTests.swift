import Combine
import Coordinator
@testable import Magnesium
import MVVMModels
import Preferences
import XCTest

class SettingsCoordinatorTests: XCTestCase {
    private let window = UIWindow()
    private let preferences = InMemoryPreferences()
    private lazy var session = Session(preferences: preferences)
    private var coordinator: SettingsCoordinator!
    private var cancellables = Set<AnyCancellable>()

    override func setUp() {
        super.setUp()
        coordinator = SettingsCoordinator(session: session, preferences: preferences)

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
        var event: SettingsCoordinatorEvent?
        coordinator.events.first().sink { event = $0 }.store(in: &cancellables)
        coordinator.handle(.complete)
        guard case .complete = event else {
            XCTFail("Unexpected event: \(String(describing: event))")
            return
        }
    }

    func test_settingsEvent_alert_shouldPresentAlertController() {
        coordinator.handle(.alert(Alert(title: "", message: nil, style: .alert)))
        let viewController = coordinator.presentable.viewController
        guard type(of: viewController.presentedViewController!) === UIAlertController.self else {
            XCTFail("Unexpected view controller: \(String(describing: viewController))")
            return
        }
    }

    func test_settingsEvent_editServer_withTransmissionServer_shouldPushServerSettingsViewController() {
        coordinator.handle(.editServer(.transmissionMock()))
        RunLoop.main.run(until: Date())
        let navigationController = coordinator.presentable.viewController as! UINavigationController
        let viewController = navigationController.viewControllers[1]
        guard type(of: viewController) === ServerSettingsViewController<AnyServerSettingsViewModel>.self else {
            XCTFail("Unexpected view controller: \(String(describing: viewController))")
            return
        }
    }

    func test_settingsEvent_editServer_withDelugeServer_shouldPushServerSettingsViewController() {
        coordinator.handle(.editServer(.delugeMock()))
        RunLoop.main.run(until: Date())
        let navigationController = coordinator.presentable.viewController as! UINavigationController
        let viewController = navigationController.viewControllers[1]
        guard type(of: viewController) === ServerSettingsViewController<AnyServerSettingsViewModel>.self else {
            XCTFail("Unexpected view controller: \(String(describing: viewController))")
            return
        }
    }

    func test_settingsEvent_addServer_shouldPushAddServerViewController() {
        coordinator.handle(.addServer)
        RunLoop.main.run(until: Date())
        let navigationController = coordinator.presentable.viewController as! UINavigationController
        let viewController = navigationController.viewControllers[1]
        guard type(of: viewController) === AddServerViewController<AddServerViewModel>.self else {
            XCTFail("Unexpected view controller: \(String(describing: viewController))")
            return
        }
    }

    func test_settingsEvent_showRefreshIntervalSettings_shouldPushRefreshIntervalViewController() {
        coordinator.handle(.showRefreshIntervalSettings)
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

        coordinator.handle(.editServer(.transmissionMock()))
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

        coordinator.handle(.editServer(.transmissionMock()))
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
