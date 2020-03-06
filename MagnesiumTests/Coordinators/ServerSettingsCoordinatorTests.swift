import Combine
@testable import Magnesium
import Preferences
import XCTest

class ServerSettingsCoordinatorTests: XCTestCase {
    private let window = UIWindow()
    private let preferences = InMemoryPreferences()
    private var coordinator: ServerSettingsCoordinator!
    private var observers = [AnyCancellable]()

    override func setUp() {
        super.setUp()
        coordinator = ServerSettingsCoordinator(type: .transmission, preferences: preferences)
        // the view controller needs to be in a key window to perform a presentation
        window.rootViewController = coordinator.presentable.viewController
        window.makeKeyAndVisible()
    }

    // MARK: presentable

    func test_presentable_withDelugeServer_shouldBeServerSettingsViewController() {
        let coordinator = ServerSettingsCoordinator(server: .delugeMock(), preferences: preferences)
        let viewController = coordinator.presentable.viewController
        guard type(of: viewController) === ServerSettingsViewController<AnyServerSettingsViewModel>.self else {
            XCTFail("Unexpected view controller: \(String(describing: viewController))")
            return
        }
    }

    func test_presentable_withTransmissionServer_shouldBeServerSettingsViewController() {
        let coordinator = ServerSettingsCoordinator(server: .transmissionMock(), preferences: preferences)
        let viewController = coordinator.presentable.viewController
        guard type(of: viewController) === ServerSettingsViewController<AnyServerSettingsViewModel>.self else {
            XCTFail("Unexpected view controller: \(String(describing: viewController))")
            return
        }
    }

    func test_presentable_withDelugeServerType_shouldBeServerSettingsViewController() {
        let coordinator = ServerSettingsCoordinator(type: .deluge, preferences: preferences)
        let viewController = coordinator.presentable.viewController
        guard type(of: viewController) === ServerSettingsViewController<AnyServerSettingsViewModel>.self else {
            XCTFail("Unexpected view controller: \(String(describing: viewController))")
            return
        }
    }

    func test_presentable_withTransmissionServerType_shouldBeServerSettingsViewController() {
        let coordinator = ServerSettingsCoordinator(type: .transmission, preferences: preferences)
        let viewController = coordinator.presentable.viewController
        guard type(of: viewController) === ServerSettingsViewController<AnyServerSettingsViewModel>.self else {
            XCTFail("Unexpected view controller: \(String(describing: viewController))")
            return
        }
    }

    // MARK: handle - ServerSettingsEvent

    func test_serverSettings_completeEvent_shouldEmitCompleteEvent() {
        var event: ServerSettingsCoordinatorEvent?
        coordinator.events.first().sink { event = $0 }.store(in: &observers)
        coordinator.handle(.complete)
        guard case .complete = event else {
            XCTFail("Unexpected event: \(String(describing: event))")
            return
        }
    }

    func test_serverSettings_alertEvent_shouldPresentAlertController() {
        coordinator.handle(.alert(Alert(title: "", message: nil, style: .alert), source: nil))
        let viewController = coordinator.presentable.viewController.presentedViewController!
        guard type(of: viewController) == UIAlertController.self else {
            XCTFail("Unexpected view controller: \(String(describing: viewController))")
            return
        }
    }
}
