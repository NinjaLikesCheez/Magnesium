import Combine
@testable import Magnesium
import XCTest

class ServerErrorCoordinatorTests: TestCase {
    private var coordinator: ServerErrorCoordinator!

    override func setUp() {
        super.setUp()
        coordinator = ServerErrorCoordinator(server: .mock(.transmission))
    }

    // MARK: - Presentable

    func test_presentable_shouldBeExpectedViewController() {
        let viewController = coordinator.presentable.viewController
        XCTAssertType(viewController, ServerErrorViewController<ServerErrorViewModel>.self)
    }

    // MARK: - ServerErrorEvent

    func test_serverErrorEvent_showSettings_shouldEmitShowSettings() throws {
        let event = try coordinator.events.first().wait {
            self.coordinator.receive(.showSettings)
        }.value()
        XCTAssertCase(event, .showSettings)
    }

    func test_serverErrorEvent_editServer_shouldEmitEditServerEvent() throws {
        let event = try coordinator.events.first().wait {
            self.coordinator.receive(.editServer)
        }.value()
        XCTAssertCase(event, type(of: event).editServer)
    }
}
