import Combine
@testable import Magnesium
import XCTest

class ServerErrorCoordinatorTests: XCTestCase {
    private var coordinator: ServerErrorCoordinator!
    private var cancellables = Set<AnyCancellable>()

    override func setUp() {
        super.setUp()
        coordinator = ServerErrorCoordinator(server: .transmissionMock())
    }

    // MARK: - Presentable

    func test_presentable_shouldBeExpectedViewController() {
        let viewController = coordinator.presentable.viewController
        guard type(of: viewController) === ServerErrorViewController<ServerErrorViewModel>.self else {
            XCTFail("Unexpected view controller: \(String(describing: viewController))")
            return
        }
    }

    // MARK: - ServerErrorEvent

    func test_serverErrorEvent_showSettings_shouldEmitShowSettings() {
        var event: ServerErrorCoordinatorEvent?
        coordinator.events.sink { event = $0 }.store(in: &cancellables)
        coordinator.handle(.showSettings)
        guard case .showSettings = event else {
            XCTFail("Unexpected event: \(String(describing: event))")
            return
        }
    }

    func test_serverErrorEvent_editServer_shouldEmitEditServerEvent() {
        var event: ServerErrorCoordinatorEvent?
        coordinator.events.sink { event = $0 }.store(in: &cancellables)
        coordinator.handle(.editServer)
        guard case .editServer = event else {
            XCTFail("Unexpected event: \(String(describing: event))")
            return
        }
    }
}
