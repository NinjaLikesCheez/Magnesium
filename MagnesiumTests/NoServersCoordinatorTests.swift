import Combine
@testable import Magnesium
import XCTest

class NoServersCoordinatorTests: TestCase {
    private var coordinator: NoServersCoordinator!

    override func setUp() {
        super.setUp()
        coordinator = NoServersCoordinator()
    }

    // MARK: - Presentable

    func test_presentable_shouldBeExpectedViewController() {
        let viewController = coordinator.presentable.viewController
        XCTAssertType(viewController, NoServersViewController<NoServersViewModel>.self)
    }

    // MARK: - NoServersEvent

    func test_noServersEvent_showSettings_shouldEmitShowSettings() throws {
        let event = try coordinator.eventPublisher.first().wait {
            self.coordinator.send(.showSettings)
        }.value()
        XCTAssertCase(event, .showSettings)
    }

    func test_noServersEvent_addServer_shouldEmitAddServerEvent() throws {
        let event = try coordinator.eventPublisher.first().wait {
            self.coordinator.send(.addServer)
        }.value()
        XCTAssertCase(event, .addServer)
    }
}
