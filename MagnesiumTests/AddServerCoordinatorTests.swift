import Combine
@testable import Magnesium
import Preferences
import XCTest

class AddServerCoordinatorTests: XCTestCase {
    private let window = UIWindow()
    private var navigationController: UINavigationController!
    private var coordinator: AddServerCoordinator!
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        Current = .mock
        coordinator = AddServerCoordinator()
        navigationController = UINavigationController(rootViewController: coordinator.presentable.viewController)
        cancellables = Set()
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

    // MARK: AddServerViewModelEvent

    func test_addServerEvent_addServer_shouldPushViewController() {
        coordinator.receive(.addServer(.deluge))
        RunLoop.main.run(until: Date())
        let navigationController = coordinator.presentable.viewController.navigationController!
        XCTAssertEqual(navigationController.viewControllers.count, 2)
    }

    func test_addServerEvent_complete_shouldEmitCompleteEvent() {
        var event: AddServerCoordinatorEvent?
        coordinator.events.sink { event = $0 }.store(in: &cancellables)
        coordinator.receive(AddServerViewModelEvent.complete)
        guard case .complete = event else {
            XCTFail("Unexpected event: \(String(describing: event))")
            return
        }
    }

    // MARK: ServerSettingsCoordinatorEvent

    func test_serverSettingsCoordinatorEvent_complete_shouldEmitCompleteEvent() {
        var event: AddServerCoordinatorEvent?
        coordinator.events.sink { event = $0 }.store(in: &cancellables)
        coordinator.handle(ServerSettingsCoordinatorEvent.complete)
        guard case .complete = event else {
            XCTFail("Unexpected event: \(String(describing: event))")
            return
        }
    }
}
