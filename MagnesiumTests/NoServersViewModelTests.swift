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
        let event = try viewModel.events.first().wait {
            self.viewModel.receive(.settingsSelected)
        }.value()
        XCTAssertCase(event, .showSettings)
    }

    func test_noServersViewEvent_addServerSelected_showEmitAddServer() throws {
        let event = try viewModel.events.first().wait {
            self.viewModel.receive(.addServerSelected)
        }.value()
        XCTAssertCase(event, .addServer)
    }
}
