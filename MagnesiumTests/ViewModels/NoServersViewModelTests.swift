import Combine
@testable import Magnesium
import XCTest

class NoServersViewModelTests: XCTestCase {
    private var viewModel: NoServersViewModel!
    private var observers = [AnyCancellable]()

    override func setUp() {
        super.setUp()
        viewModel = NoServersViewModel()
    }

    // MARK: NoServersViewEvent

    func test_noServersViewEvent_settingsSelected_shouldEmitShowSettings() {
        var event: NoServersEvent?
        viewModel.events.sink { event = $0 }.store(in: &observers)
        viewModel.handle(.settingsSelected)
        guard case .showSettings = event else {
            XCTFail("Unexpected event: \(String(describing: event))")
            return
        }
    }

    func test_noServersViewEvent_addServerSelected_showEmitAddServer() {
        var event: NoServersEvent?
        viewModel.events.sink { event = $0 }.store(in: &observers)
        viewModel.handle(.addServerSelected)
        guard case .addServer = event else {
            XCTFail("Unexpected event: \(String(describing: event))")
            return
        }
    }
}
