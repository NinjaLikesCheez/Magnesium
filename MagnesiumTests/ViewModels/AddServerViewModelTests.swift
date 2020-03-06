import Combine
@testable import Magnesium
import XCTest

class AddServerViewModelTests: XCTestCase {
    private var observers = [AnyCancellable]()
    private let viewModel = AddServerViewModel()

    func test_types() {
        XCTAssertEqual(viewModel.state.types, ["Deluge", "Transmission"])
    }

    func test_typeSelected_withDeluge_shouldEmitDelugeAddServerType() {
        var event: AddServerEvent?
        viewModel.events.sink { event = $0 }.store(in: &observers)
        viewModel.handle(.typeSelected(index: 0))
        guard case let .addServer(type) = event else {
            XCTFail("Unexpected event: \(String(describing: event))")
            return
        }
        XCTAssertEqual(type, ServerType.deluge)
    }

    func test_typeSelected_withTransmission_shouldEmitTransmissionAddServerType() {
        var event: AddServerEvent?
        viewModel.events.sink { event = $0 }.store(in: &observers)
        viewModel.handle(.typeSelected(index: 1))
        guard case let .addServer(type) = event else {
            XCTFail("Unexpected event: \(String(describing: event))")
            return
        }
        XCTAssertEqual(type, ServerType.transmission)
    }

    func test_cancelSelected_shouldEmitCompleteEvent() {
        var event: AddServerEvent?
        viewModel.events.sink { event = $0 }.store(in: &observers)
        viewModel.handle(.cancelSelected)
        guard case .complete = event else {
            XCTFail("Unexpected event: \(String(describing: event))")
            return
        }
    }
}
