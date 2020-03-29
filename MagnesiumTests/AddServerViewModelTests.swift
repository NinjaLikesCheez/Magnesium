import Combine
@testable import Magnesium
import XCTest

class AddServerViewModelTests: TestCase {
    private var viewModel: AddServerViewModel!

    override func setUp() {
        super.setUp()
        viewModel = AddServerViewModel()
    }

    func test_types() {
        XCTAssertEqual(viewModel.values.types, ["Deluge", "Transmission"])
    }

    func test_typeSelected_withDeluge_shouldEmitDelugeAddServerType() throws {
        let event = try viewModel.events.first().wait {
            self.viewModel.receive(.typeSelected(index: 0))
        }.value()
        let type = try extract(case: Swift.type(of: event).addServer, from: event)
        XCTAssertEqual(type, .deluge)
    }

    func test_typeSelected_withTransmission_shouldEmitTransmissionAddServerType() throws {
        let event = try viewModel.events.first().wait {
            self.viewModel.receive(.typeSelected(index: 1))
        }.value()
        let type = try extract(case: Swift.type(of: event).addServer, from: event)
        XCTAssertEqual(type, .transmission)
    }

    func test_cancelSelected_shouldEmitCompleteEvent() throws {
        let event = try viewModel.events.first().wait {
            self.viewModel.receive(.cancelSelected)
        }.value()
        XCTAssertCase(event, .complete)
    }
}
