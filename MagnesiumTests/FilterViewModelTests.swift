//
//  FilterViewModelTests.swift
//  MagnesiumTests
//
//  Created by James Hurst on 2020-01-31.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
@testable import Magnesium
import XCTest

class FilterViewModelTests: XCTestCase {
    private let preferences = MockPreferences()
    private lazy var viewModel = FilterViewModel(preferences: preferences)
    private var observers = [AnyCancellable]()

    func test_sortOption_shouldBeFormattedCorrectly() {
        let expectation = self.expectation(description: "Value received")
        viewModel.state.sortOption.first().sink { state in
            XCTAssertEqual(state, "↑ Name")
            expectation.fulfill()
        }.store(in: &observers)
        waitForExpectations(timeout: 0)
    }

    func test_sortOption_whenChanged_shouldEmitNewValue() {
        let expectation = self.expectation(description: "Value received")
        viewModel.state.sortOption.dropFirst().first().sink { state in
            XCTAssertEqual(state, "↓ Date Added")
            expectation.fulfill()
        }.store(in: &observers)
        preferences.set(SortOption(property: .dateAdded), for: PreferenceKeys.sortOption)
        waitForExpectations(timeout: 0)
    }

    func test_handleDoneSelected_shouldEmitComplete() {
        let expectation = self.expectation(description: "Value received")
        viewModel.events.first().sink { event in
            guard case .complete = event else {
                XCTFail("Unexpected event")
                return
            }
            expectation.fulfill()
        }.store(in: &observers)
        viewModel.handle(.doneSelected)
        waitForExpectations(timeout: 0)
    }

    func test_handleSortSelected_shouldEmitAlert() {
        let expected = ["Name", "Date Added", "Download Speed", "Upload Speed", "Cancel"]
        var alert: Alert?
        viewModel.events.first().sink { event in
            guard case let .alert(inner, _) = event else { return }
            alert = inner
        }.store(in: &observers)
        viewModel.handle(.sortSelected(source: .view(UIView(), rect: .zero)))
        XCTAssertEqual(alert?.actions.map { $0.title }, expected)
    }

    func test_handleSortSelected__whenExistingOptionSelected_shouldInvert() {
        var alert: Alert?
        viewModel.events.first().sink { event in
            guard case let .alert(inner, _) = event else { return }
            alert = inner
        }.store(in: &observers)
        viewModel.handle(.sortSelected(source: .view(UIView(), rect: .zero)))
        let previousOption = preferences.value(for: PreferenceKeys.sortOption)
        alert?.actions.first { $0.title == "Name" }?.handler?()
        let newOption = preferences.value(for: PreferenceKeys.sortOption)
        XCTAssertEqual(newOption, previousOption.withOppositeDirection())
    }

    func test_handleSortSelected__withNewOption_shouldSetNewOption() {
        var alert: Alert?
        viewModel.events.first().sink { event in
            guard case let .alert(inner, _) = event else { return }
            alert = inner
        }.store(in: &observers)
        viewModel.handle(.sortSelected(source: .view(UIView(), rect: .zero)))
        alert?.actions.first { $0.title == "Date Added" }?.handler?()
        let newOption = preferences.value(for: PreferenceKeys.sortOption)
        XCTAssertEqual(newOption, SortOption(property: .dateAdded))
    }
}
