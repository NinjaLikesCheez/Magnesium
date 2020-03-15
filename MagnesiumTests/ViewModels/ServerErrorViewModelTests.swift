import Combine
@testable import Magnesium
import XCTest

class ServerErrorViewModelTests: XCTestCase {
    private var viewModel: ServerErrorViewModel!
    private var cancellables = Set<AnyCancellable>()

    override func setUp() {
        super.setUp()
        viewModel = ServerErrorViewModel()
    }

    // MARK: ServerErrorViewEvent

    func test_serverErrorViewEvent_settingsSelected_shouldEmitShowSettings() {
        var event: ServerErrorEvent?
        viewModel.events.sink { event = $0 }.store(in: &cancellables)
        viewModel.handle(.settingsSelected)
        guard case .showSettings = event else {
            XCTFail("Unexpected event: \(String(describing: event))")
            return
        }
    }

    func test_serverErrorViewEvent_editServerSelected_showEmitEditServer() {
        var event: ServerErrorEvent?
        viewModel.events.sink { event = $0 }.store(in: &cancellables)
        viewModel.handle(.editServerSelected)
        guard case .editServer = event else {
            XCTFail("Unexpected event: \(String(describing: event))")
            return
        }
    }
}
