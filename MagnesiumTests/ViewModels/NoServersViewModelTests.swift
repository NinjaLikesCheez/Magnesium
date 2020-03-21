import Combine
@testable import Magnesium
import XCTest

class NoServersViewModelTests: XCTestCase {
    private var viewModel: NoServersViewModel!
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        Current = .mock
        viewModel = NoServersViewModel()
        cancellables = Set()
    }

    // MARK: NoServersViewEvent

    func test_noServersViewEvent_settingsSelected_shouldEmitShowSettings() {
        var event: NoServersEvent?
        viewModel.events.sink { event = $0 }.store(in: &cancellables)
        viewModel.handle(.settingsSelected)
        guard case .showSettings = event else {
            XCTFail("Unexpected event: \(String(describing: event))")
            return
        }
    }

    func test_noServersViewEvent_addServerSelected_showEmitAddServer() {
        var event: NoServersEvent?
        viewModel.events.sink { event = $0 }.store(in: &cancellables)
        viewModel.handle(.addServerSelected)
        guard case .addServer = event else {
            XCTFail("Unexpected event: \(String(describing: event))")
            return
        }
    }
}
