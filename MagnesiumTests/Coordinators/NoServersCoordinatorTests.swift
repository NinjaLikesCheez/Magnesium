import Combine
@testable import Magnesium
import XCTest

class NoServersCoordinatorTests: XCTestCase {
    private var coordinator: NoServersCoordinator!
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        Current = .mock
        coordinator = NoServersCoordinator()
        cancellables = Set()
    }

    // MARK: - Presentable

    func test_presentable_shouldBeExpectedViewController() {
        let viewController = coordinator.presentable.viewController
        guard type(of: viewController) === NoServersViewController<NoServersViewModel>.self else {
            XCTFail("Unexpected view controller: \(String(describing: viewController))")
            return
        }
    }

    // MARK: - NoServersEvent

    func test_noServersEvent_showSettings_shouldEmitShowSettings() {
        var event: NoServersCoordinatorEvent?
        coordinator.events.sink { event = $0 }.store(in: &cancellables)
        coordinator.handle(.showSettings)
        guard case .showSettings = event else {
            XCTFail("Unexpected event: \(String(describing: event))")
            return
        }
    }

    func test_noServersEvent_addServer_shouldEmitAddServerEvent() {
        var event: NoServersCoordinatorEvent?
        coordinator.events.sink { event = $0 }.store(in: &cancellables)
        coordinator.handle(.addServer)
        guard case .addServer = event else {
            XCTFail("Unexpected event: \(String(describing: event))")
            return
        }
    }
}
