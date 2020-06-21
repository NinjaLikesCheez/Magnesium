import Combine
import CommonModels
@testable import Magnesium
import Preferences
import XCTest

class ServerSettingsCoordinatorTests: TestCase {
    private var window: UIWindow!
    private var coordinator: ServerSettingsCoordinator!
    private var preferences: Preferences { Current.preferences }

    override func setUp() {
        super.setUp()
        window = UIWindow()
        coordinator = ServerSettingsCoordinator(type: .transmission)
        // the view controller needs to be in a key window to perform a presentation
        window.rootViewController = coordinator.presentable.viewController
        window.makeKeyAndVisible()
    }

    // MARK: presentable

    func test_presentable_withDelugeServer_shouldBeServerSettingsViewController() {
        let coordinator = ServerSettingsCoordinator(server: .mock(.deluge))
        let viewController = coordinator.presentable.viewController
        XCTAssertType(viewController, ServerSettingsViewController<AnyServerSettingsViewModel>.self)
    }

    func test_presentable_withTransmissionServer_shouldBeServerSettingsViewController() {
        let coordinator = ServerSettingsCoordinator(server: .mock(.transmission))
        let viewController = coordinator.presentable.viewController
        XCTAssertType(viewController, ServerSettingsViewController<AnyServerSettingsViewModel>.self)
    }

    func test_presentable_withDelugeServerType_shouldBeServerSettingsViewController() {
        let coordinator = ServerSettingsCoordinator(type: .deluge)
        let viewController = coordinator.presentable.viewController
        XCTAssertType(viewController, ServerSettingsViewController<AnyServerSettingsViewModel>.self)
    }

    func test_presentable_withTransmissionServerType_shouldBeServerSettingsViewController() {
        let coordinator = ServerSettingsCoordinator(type: .transmission)
        let viewController = coordinator.presentable.viewController
        XCTAssertType(viewController, ServerSettingsViewController<AnyServerSettingsViewModel>.self)
    }

    // MARK: handle - ServerSettingsEvent

    func test_serverSettings_completeEvent_shouldEmitCompleteEvent() throws {
        let event = try coordinator.eventPublisher.first().wait {
            self.coordinator.send(.complete)
        }.singleValue()
        XCTAssertCase(event, .complete)
    }

    func test_serverSettings_alertEvent_shouldPresentAlertController() {
        coordinator.send(.alert(Alert(title: "", style: .alert)))
        let viewController = coordinator.presentable.viewController.presentedViewController
        XCTAssertType(viewController, UIAlertController.self)
    }
}
