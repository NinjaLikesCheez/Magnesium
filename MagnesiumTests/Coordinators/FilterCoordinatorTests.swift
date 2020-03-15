import Combine
@testable import Magnesium
import Preferences
import XCTest

class FilterCoordinatorTests: XCTestCase {
    private let window = UIWindow()
    private let preferences = InMemoryPreferences()
    private var coordinator: FilterCoordinator!
    private var cancellables = Set<AnyCancellable>()

    override func setUp() {
        super.setUp()
        coordinator = FilterCoordinator(preferences: preferences, labels: CurrentValueSubject([]))

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

    func test_filterEvent_complete_shouldEmitCompleteEvent() {
        var event: FilterCoordinatorEvent?
        coordinator.events.first().sink { event = $0 }.store(in: &cancellables)
        coordinator.handle(.complete)
        guard case .complete = event else {
            XCTFail("Unexpected event: \(String(describing: event))")
            return
        }
    }

    func test_settingsEvent_alert_shouldPresentAlertController() {
        coordinator.handle(.alert(
            Alert(title: "", message: nil, style: .alert),
            source: .view(UIView(), rect: .zero)
        ))
        let viewController = coordinator.presentable.viewController
        guard type(of: viewController.presentedViewController!) === UIAlertController.self else {
            XCTFail("Unexpected view controller: \(String(describing: viewController))")
            return
        }
    }
}
