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
        let event = try viewModel.eventPublisher.first().wait {
            self.viewModel.send(.settingsSelected)
        }.value()
        XCTAssertCase(event, .showSettings)
    }

    func test_serverErrorViewEvent_editServerSelected_showEmitEditServer() throws {
        let event = try viewModel.eventPublisher.first().wait {
            self.viewModel.send(.editServerSelected)
        }.value()
        XCTAssertCase(event, .editServer)
    }
}
