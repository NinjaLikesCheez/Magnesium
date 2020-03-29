import Combine
@testable import Magnesium
import Preferences
import XCTest

class RefreshIntervalViewModelTests: XCTestCase {
    private var viewModel: RefreshIntervalViewModel!
    private var cancellables: Set<AnyCancellable>!
    private var preferences: Preferences { Current.preferences }

    override func setUp() {
        super.setUp()
        Current = .mock
        preferences[.autoRefreshInterval] = 2
        viewModel = RefreshIntervalViewModel()
        cancellables = Set()
    }

    func test_options_names() {
        let expected = ["Never", "2 seconds", "5 seconds", "10 seconds", "30 seconds"]
        XCTAssertEqual(viewModel.view.options.map(\.title), expected)
    }

    func test_options_values() {
        let values = [0, 2, 5]
        for (index, value) in values.enumerated() {
            viewModel.receive(.optionSelected(index: index))
            XCTAssertEqual(preferences[.autoRefreshInterval], value)
        }
    }

    func test_option_whenIsCurrent_shouldBeSelected() {
        var values = [Bool]()
        viewModel.view.options.first { $0.title == "2 seconds" }?.isSelected.sink {
            values.append($0)
        }.store(in: &cancellables)
        XCTAssertEqual(values, [true])
    }

    func test_option_whenNoLongerCurrent_shouldDeselect() {
        var values = [Bool]()
        viewModel.view.options.first { $0.title == "2 seconds" }?.isSelected.sink {
            values.append($0)
        }.store(in: &cancellables)
        XCTAssertEqual(values, [true])
        viewModel.receive(.optionSelected(index: 0))
        XCTAssertEqual(values, [true, false])
    }

    func test_option_whenSelected_shouldBecomeSelected() {
        var values = [Bool]()
        viewModel.view.options.first?.isSelected.sink {
            values.append($0)
        }.store(in: &cancellables)
        XCTAssertEqual(values, [false])
        viewModel.receive(.optionSelected(index: 0))
        XCTAssertEqual(values, [false, true])
    }
}
