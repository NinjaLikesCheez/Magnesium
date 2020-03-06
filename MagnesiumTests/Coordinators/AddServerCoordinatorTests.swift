import Combine
@testable import Magnesium
import XCTest

class AddServerCoordinatorTests: XCTestCase {
    private let window = UIWindow()
    private let preferences = MockPreferences()
    private var navigationController: UINavigationController!
    private var coordinator: AddServerCoordinator!
    private var observers = [AnyCancellable]()

    override func setUp() {
        super.setUp()
        coordinator = AddServerCoordinator(preferences: preferences)
        navigationController = UINavigationController(rootViewController: coordinator.presentable.viewController)
        // the view controller needs to be in a key window to perform a presentation
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
    }

    func test_presentable_shouldBeAddServerViewController() {
        let viewController = coordinator.presentable.viewController
        guard type(of: viewController) == AddServerViewController<AddServerViewModel>.self else {
            XCTFail("Unexpected view controller: \(String(describing: viewController))")
            return
        }
    }

    // MARK: AddServerEvent

    func test_addServerEvent_addServer_shouldPushViewController() {
        coordinator.handle(.addServer(.deluge))
        RunLoop.main.run(until: Date())
        let navigationController = coordinator.presentable.viewController.navigationController!
        XCTAssertEqual(navigationController.viewControllers.count, 2)
    }

    func test_addServerEvent_complete_shouldEmitCompleteEvent() {
        var event: AddServerCoordinatorEvent?
        coordinator.events.sink { event = $0 }.store(in: &observers)
        coordinator.handle(AddServerEvent.complete)
        guard case .complete = event else {
            XCTFail("Unexpected event: \(String(describing: event))")
            return
        }
    }

    // MARK: ServerSettingsCoordinatorEvent

    func test_serverSettingsCoordinatorEvent_complete_shouldEmitCompleteEvent() {
        var event: AddServerCoordinatorEvent?
        coordinator.events.sink { event = $0 }.store(in: &observers)
        coordinator.handle(ServerSettingsCoordinatorEvent.complete)
        guard case .complete = event else {
            XCTFail("Unexpected event: \(String(describing: event))")
            return
        }
    }
}
