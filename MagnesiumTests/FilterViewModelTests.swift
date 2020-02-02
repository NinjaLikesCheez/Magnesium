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
        viewModel.state.sortOption.first().sink { value in
            XCTAssertEqual(value, "↑ Name")
            expectation.fulfill()
        }.store(in: &observers)
        waitForExpectations(timeout: 0)
    }

    func test_sortOption_whenChanged_shouldEmitNewValue() {
        let expectation = self.expectation(description: "Value received")
        viewModel.state.sortOption.dropFirst().first().sink { value in
            XCTAssertEqual(value, "↓ Date Added")
            expectation.fulfill()
        }.store(in: &observers)
        preferences.set(SortOption(property: .dateAdded), for: PreferenceKeys.sortOption)
        waitForExpectations(timeout: 0)
    }

    func test_filterState_whenNil_shouldBeAll() {
        let expectation = self.expectation(description: "Value received")
        viewModel.state.filterState.first().sink { value in
            XCTAssertEqual(value, "All")
            expectation.fulfill()
        }.store(in: &observers)
        waitForExpectations(timeout: 0)
    }

    func test_filterState_whenChanged_shouldEmitNewValue() {
        let expectation = self.expectation(description: "Value received")
        viewModel.state.filterState.dropFirst().first().sink { value in
            XCTAssertEqual(value, "Downloading")
            expectation.fulfill()
        }.store(in: &observers)
        preferences.set(FilterOptions(state: .downloading), for: PreferenceKeys.filterOptions)
        waitForExpectations(timeout: 0)
    }

    func test_doneSelected_shouldEmitCompleteEvent() {
        var event: FilterEvent?
        viewModel.events.first().sink {
            event = $0
        }.store(in: &observers)
        viewModel.handle(.doneSelected)
        guard case .complete = event else {
            XCTFail("Unexpected event")
            return
        }
    }

    func test_sortSelected_shouldEmitAlert() {
        let expected = ["Name", "Date Added", "Download Speed", "Upload Speed", "Cancel"]
        var alert: Alert?
        viewModel.events.first().sink { event in
            guard case let .alert(inner, _) = event else { return }
            alert = inner
        }.store(in: &observers)
        viewModel.handle(.sortSelected(source: .view(UIView(), rect: .zero)))
        XCTAssertEqual(alert?.actions.map { $0.title }, expected)
    }

    func test_sortSelected__whenExistingOptionSelected_shouldInvert() {
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

    func test_sortSelected__withNewOption_shouldSetNewOption() {
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

    func test_filterStateSelected_shouldEmitAlert() {
        let expected = ["All", "Downloading", "Seeding", "Paused", "Checking", "Queued", "Error", "Cancel"]
        var alert: Alert?
        viewModel.events.first().sink { event in
            guard case let .alert(inner, _) = event else { return }
            alert = inner
        }.store(in: &observers)
        viewModel.handle(.filterStateSelected(source: .view(UIView(), rect: .zero)))
        XCTAssertEqual(alert?.actions.map { $0.title }, expected)
    }

    func test_filterStateSelected__withNewOption_shouldSetNewOption() {
        var alert: Alert?
        viewModel.events.first().sink { event in
            guard case let .alert(inner, _) = event else { return }
            alert = inner
        }.store(in: &observers)
        viewModel.handle(.filterStateSelected(source: .view(UIView(), rect: .zero)))
        alert?.actions.first { $0.title == "Downloading" }?.handler?()
        let newOption = preferences.value(for: PreferenceKeys.filterOptions)
        XCTAssertEqual(newOption, FilterOptions(state: .downloading))
    }
}
