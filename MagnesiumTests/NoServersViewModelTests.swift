import Combine
@testable import Magnesium
import XCTest

class NoServersViewModelTests: TestCase {
    private var viewModel: NoServersViewModel!

    override func setUp() {
        super.setUp()
        viewModel = NoServersViewModel()
    }

    // MARK: NoServersViewEvent

    func test_noServersViewEvent_settingsSelected_shouldEmitShowSettings() throws {
        let event = try viewModel.eventPublisher.first().wait {
            self.viewModel.send(.settingsSelected)
        }.value()
        XCTAssertCase(event, .showSettings)
    }

    func test_noServersViewEvent_addServerSelected_showEmitAddServer() throws {
        let event = try viewModel.eventPublisher.first().wait {
            self.viewModel.send(.addServerSelected)
        }.value()
        XCTAssertCase(event, .addServer)
    }
}
