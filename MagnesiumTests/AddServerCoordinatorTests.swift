import Combine
@testable import Magnesium
import Preferences
import XCTest

class AddServerCoordinatorTests: TestCase {
    private let window = UIWindow()
    private var navigationController: UINavigationController!
    private var coordinator: AddServerCoordinator!

    override func setUp() {
        super.setUp()
        coordinator = AddServerCoordinator()
        navigationController = UINavigationController(rootViewController: coordinator.presentable.viewController)
        // the view controller needs to be in a key window to perform a presentation
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
    }

    func test_presentable_shouldBeAddServerViewController() {
        let viewController = coordinator.presentable.viewController
        XCTAssertType(viewController, AddServerViewController<AddServerViewModel>.self)
    }

    // MARK: AddServerViewModelEvent

    func test_addServerEvent_addServer_shouldPushViewController() {
        coordinator.send(.addServer(.deluge))
        RunLoop.main.run(until: Date())
        let navigationController = coordinator.presentable.viewController.navigationController!
        XCTAssertEqual(navigationController.viewControllers.count, 2)
    }

    func test_addServerEvent_complete_shouldEmitCompleteEvent() throws {
        let event = try coordinator.eventPublisher.first().wait {
            self.coordinator.send(AddServerViewModelEvent.complete)
        }.singleValue()
        XCTAssertCase(event, .complete)
    }

    // MARK: ServerSettingsCoordinatorEvent

    func test_serverSettingsCoordinatorEvent_complete_shouldEmitCompleteEvent() throws {
        let event = try coordinator.eventPublisher.first().wait {
            self.coordinator.handle(ServerSettingsCoordinatorEvent.complete)
        }.singleValue()
        XCTAssertCase(event, .complete)
    }
}
