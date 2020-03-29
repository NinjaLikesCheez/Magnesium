import Combine
@testable import Magnesium
import XCTest

class ServerErrorViewModelTests: TestCase {
    private var viewModel: ServerErrorViewModel!

    override func setUp() {
        super.setUp()
        viewModel = ServerErrorViewModel()
    }

    // MARK: ServerErrorViewEvent

    func test_serverErrorViewEvent_settingsSelected_shouldEmitShowSettings() throws {
        let event = try viewModel.events.first().wait {
            self.viewModel.receive(.settingsSelected)
        }.value()
        XCTAssertCase(event, .showSettings)
    }

    func test_serverErrorViewEvent_editServerSelected_showEmitEditServer() throws {
        let event = try viewModel.events.first().wait {
            self.viewModel.receive(.editServerSelected)
        }.value()
        XCTAssertCase(event, .editServer)
    }
}
