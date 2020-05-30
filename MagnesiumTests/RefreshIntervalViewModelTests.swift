import Combine
@testable import Magnesium
import Preferences
import XCTest

class RefreshIntervalViewModelTests: TestCase {
    private var viewModel: RefreshIntervalViewModel!
    private var preferences: Preferences { Current.preferences }

    override func setUp() {
        super.setUp()
        preferences[.autoRefreshInterval] = 2
        viewModel = RefreshIntervalViewModel()
    }

    func test_options_names() {
        let expected = ["Never", "2 seconds", "5 seconds", "10 seconds", "30 seconds"]
        XCTAssertEqual(viewModel.values.options.map(\.title), expected)
    }

    func test_options_values() {
        let values = [0, 2, 5]
        for (index, value) in values.enumerated() {
            viewModel.send(.optionSelected(index: index))
            XCTAssertEqual(preferences[.autoRefreshInterval], value)
        }
    }

    func test_option_whenIsCurrent_shouldBeSelected() throws {
        let isSelected = try viewModel.values.options.first { $0.title == "2 seconds" }?.isSelected.wait().value()
        XCTAssertEqual(isSelected, .some(true))
    }

    func test_option_whenNoLongerCurrent_shouldDeselect() {
        let isSelected = viewModel.values.options.first { $0.title == "2 seconds" }?.isSelected.wait {
            self.viewModel.send(.optionSelected(index: 0))
        }.values()
        XCTAssertEqual(isSelected, [true, false])
    }

    func test_option_whenSelected_shouldBecomeSelected() {
        let isSelected = viewModel.values.options.first?.isSelected.wait {
            self.viewModel.send(.optionSelected(index: 0))
        }.values()
        XCTAssertEqual(isSelected, [false, true])
    }
}
