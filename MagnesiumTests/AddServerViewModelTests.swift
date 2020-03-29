import Combine
@testable import Magnesium
import XCTest

class AddServerViewModelTests: XCTestCase {
    private var viewModel: AddServerViewModel!

    override func setUp() {
        super.setUp()
        Current = .mock
        viewModel = AddServerViewModel()
    }

    func test_types() {
        XCTAssertEqual(viewModel.view.types, ["Deluge", "Transmission"])
    }

    func test_typeSelected_withDeluge_shouldEmitDelugeAddServerType() throws {
        let event = try viewModel.events.first().wait {
            self.viewModel.receive(.typeSelected(index: 0))
        }.value()
        let type = try extract(case: Swift.type(of: event).addServer, from: event)
        XCTAssertEqual(type, ServerType.deluge)
    }

    func test_typeSelected_withTransmission_shouldEmitTransmissionAddServerType() throws {
        let event = try viewModel.events.first().wait {
            self.viewModel.receive(.typeSelected(index: 1))
        }.value()
        let type = try extract(case: Swift.type(of: event).addServer, from: event)
        XCTAssertEqual(type, ServerType.transmission)
    }

    func test_cancelSelected_shouldEmitCompleteEvent() throws {
        let event = try viewModel.events.first().wait {
            self.viewModel.receive(.cancelSelected)
        }.value()
        XCTAssertCase(event, type(of: event).complete)
    }
}
