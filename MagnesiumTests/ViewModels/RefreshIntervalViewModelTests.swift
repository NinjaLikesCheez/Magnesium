import Combine
@testable import Magnesium
import XCTest

class RefreshIntervalViewModelTests: XCTestCase {
    private let preferences = MockPreferences()
    private lazy var viewModel = RefreshIntervalViewModel(preferences: preferences)
    private var observers = [AnyCancellable]()

    func test_options_names() {
        let expected = ["Never", "2 seconds", "5 seconds", "10 seconds", "30 seconds"]
        XCTAssertEqual(viewModel.state.options.map { $0.name }, expected)
    }

    func test_options_values() {
        let values = [0, 2, 5]
        for (index, value) in values.enumerated() {
            viewModel.handle(.optionSelected(index: index))
            XCTAssertEqual(preferences.value(for: .autoRefreshInterval), value)
        }
    }

    func test_option_whenIsCurrent_shouldBeSelected() {
        var values = [Bool]()
        viewModel.state.options.first { $0.name == "2 seconds" }?.isSelected.sink {
            values.append($0)
        }.store(in: &observers)
        XCTAssertEqual(values, [true])
    }

    func test_option_whenNoLongerCurrent_shouldDeselect() {
        var values = [Bool]()
        viewModel.state.options.first { $0.name == "2 seconds" }?.isSelected.sink {
            values.append($0)
        }.store(in: &observers)
        XCTAssertEqual(values, [true])
        viewModel.handle(.optionSelected(index: 0))
        XCTAssertEqual(values, [true, false])
    }

    func test_option_whenSelected_shouldBecomeSelected() {
        var values = [Bool]()
        viewModel.state.options.first?.isSelected.sink {
            values.append($0)
        }.store(in: &observers)
        XCTAssertEqual(values, [false])
        viewModel.handle(.optionSelected(index: 0))
        XCTAssertEqual(values, [false, true])
    }
}
