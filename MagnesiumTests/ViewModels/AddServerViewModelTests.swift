import Combine
@testable import Magnesium
import XCTest

class AddServerViewModelTests: XCTestCase {
    private var viewModel: AddServerViewModel!
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        Current = .mock
        viewModel = AddServerViewModel()
        cancellables = Set()
    }

    func test_types() {
        XCTAssertEqual(viewModel.view.types, ["Deluge", "Transmission"])
    }

    func test_typeSelected_withDeluge_shouldEmitDelugeAddServerType() {
        var event: AddServerViewModelEvent?
        viewModel.events.sink { event = $0 }.store(in: &cancellables)
        viewModel.receive(.typeSelected(index: 0))
        guard case let .addServer(type) = event else {
            XCTFail("Unexpected event: \(String(describing: event))")
            return
        }
        XCTAssertEqual(type, ServerType.deluge)
    }

    func test_typeSelected_withTransmission_shouldEmitTransmissionAddServerType() {
        var event: AddServerViewModelEvent?
        viewModel.events.sink { event = $0 }.store(in: &cancellables)
        viewModel.receive(.typeSelected(index: 1))
        guard case let .addServer(type) = event else {
            XCTFail("Unexpected event: \(String(describing: event))")
            return
        }
        XCTAssertEqual(type, ServerType.transmission)
    }

    func test_cancelSelected_shouldEmitCompleteEvent() {
        var event: AddServerViewModelEvent?
        viewModel.events.sink { event = $0 }.store(in: &cancellables)
        viewModel.receive(.cancelSelected)
        guard case .complete = event else {
            XCTFail("Unexpected event: \(String(describing: event))")
            return
        }
    }
}
