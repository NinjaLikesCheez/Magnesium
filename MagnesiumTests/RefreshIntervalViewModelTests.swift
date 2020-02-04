//
//  RefreshIntervalViewModelTests.swift
//  MagnesiumTests
//
//  Created by James Hurst on 2020-02-03.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
@testable import Magnesium
import XCTest

class RefreshIntervalViewModelTests: XCTestCase {
    private let preferences = MockPreferences()
    private lazy var viewModel = RefreshIntervalViewModel(preferences: preferences)
    private var observers = [AnyCancellable]()

    func test_options_names() {
        XCTAssertEqual(viewModel.state.options.map { $0.name }, ["Never", "2 seconds", "5 seconds"])
    }

    func test_options_values() {
        let values: [TimeInterval] = [0, 2, 5]
        for (index, value) in values.enumerated() {
            viewModel.handle(.optionSelected(index: index))
            XCTAssertEqual(preferences.value(for: PreferenceKeys.autoRefreshInterval), value)
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
