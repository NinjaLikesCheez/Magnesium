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
    private let labels = CurrentValueSubject<[MockLabel], Never>([MockLabel(), MockLabel(name: "test")])
    private var observers = [AnyCancellable]()
    private var viewModel: FilterViewModel!

    override func setUp() {
        super.setUp()
        let mappedLabels = CurrentValueSubject<[StandardLabel], Never>(labels.value)
        labels.sink { [weak mappedLabels] in mappedLabels?.send($0) }.store(in: &observers)
        viewModel = FilterViewModel(preferences: preferences, labels: mappedLabels)
    }

    func test_sections_withoutLabels_shouldEmitExpectedValues() {
        labels.send([])
        var sections: [FilterSection]!
        viewModel.state.sections.sink { sections = $0 }.store(in: &observers)
        let expected = [
            FilterSection(type: .sort, items: [.sort("↓ Date Added")]),
            FilterSection(type: .filters, items: [.state("All")]),
        ]
        XCTAssertEqual(sections, expected)
    }

    func test_sections_withLabels_shouldEmitExpectedValues() {
        var sections: [FilterSection]!
        viewModel.state.sections.sink { sections = $0 }.store(in: &observers)
        let expected = [
            FilterSection(type: .sort, items: [.sort("↓ Date Added")]),
            FilterSection(type: .filters, items: [.state("All"), .label("All")]),
        ]
        XCTAssertEqual(sections, expected)
    }

    func test_sections_whenSortOptionChanged_shouldEmitNewSections() {
        var sections: [FilterSection]?
        viewModel.state.sections.dropFirst().sink { sections = $0 }.store(in: &observers)
        preferences.set(SortOption(property: .name), for: PreferenceKeys.sortOption)
        XCTAssertNotNil(sections)
        XCTAssertEqual(sections?[0].items, [.sort("↑ Name")])
    }

    func test_sections_whenFilterOptionsChanged_shouldEmit() {
        var sections: [FilterSection]?
        viewModel.state.sections.dropFirst().sink { sections = $0 }.store(in: &observers)
        preferences.set(FilterOptions(state: .downloading), for: PreferenceKeys.filterOptions)
        XCTAssertNotNil(sections)
        XCTAssertEqual(sections?[1].items[0], .state("Downloading"))
    }

    func test_sections_whenLabelsUpdated_shouldEmit() {
        var sections: [FilterSection]?
        viewModel.state.sections.dropFirst().sink { sections = $0 }.store(in: &observers)
        labels.send(labels.value + [MockLabel(name: "new")])
        XCTAssertNotNil(sections)
    }

    func test_sections_withSameLabelsPublished_shouldNotEmit() {
        labels.send(labels.value)
        var sections: [FilterSection]?
        viewModel.state.sections.dropFirst().sink { sections = $0 }.store(in: &observers)
        labels.send(labels.value)
        XCTAssertNil(sections)
    }

    func test_doneSelected_shouldEmitCompleteEvent() {
        var event: FilterEvent?
        viewModel.events.first().sink {
            event = $0
        }.store(in: &observers)
        viewModel.handle(.doneSelected)
        guard case .complete = event else {
            XCTFail("Unexpected event: \(String(describing: event))")
            return
        }
    }

    func test_sortSelected_shouldEmitAlert() {
        let expected = ["Date Added", "Name", "Download Speed", "Upload Speed", "Cancel"]
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
        alert?.actions.first { $0.title == previousOption.property.localizedString }?.handler?()
        let newOption = preferences.value(for: PreferenceKeys.sortOption)
        XCTAssertEqual(newOption, previousOption.withOppositeDirection())
    }

    func test_sortSelected_withNewOption_shouldSetNewOption() {
        var alert: Alert?
        viewModel.events.first().sink { event in
            guard case let .alert(inner, _) = event else { return }
            alert = inner
        }.store(in: &observers)
        viewModel.handle(.sortSelected(source: .view(UIView(), rect: .zero)))
        alert?.actions.first { $0.title == "Name" }?.handler?()
        let newOption = preferences.value(for: PreferenceKeys.sortOption)
        XCTAssertEqual(newOption, SortOption(property: .name))
    }

    func test_stateSelected_shouldEmitAlert() {
        var alert: Alert?
        viewModel.events.first().sink { event in
            guard case let .alert(inner, _) = event else { return }
            alert = inner
        }.store(in: &observers)
        viewModel.handle(.stateSelected(source: .view(UIView(), rect: .zero)))
        let expected = ["All", "Downloading", "Seeding", "Paused", "Checking", "Queued", "Error", "Cancel"]
        XCTAssertEqual(alert?.actions.map { $0.title }, expected)
    }

    func test_stateSelected_withNewOption_shouldSetNewOption() {
        var alert: Alert?
        viewModel.events.first().sink { event in
            guard case let .alert(inner, _) = event else { return }
            alert = inner
        }.store(in: &observers)
        viewModel.handle(.stateSelected(source: .view(UIView(), rect: .zero)))
        alert?.actions.first { $0.title == "Downloading" }?.handler?()
        let newOption = preferences.value(for: PreferenceKeys.filterOptions)
        XCTAssertEqual(newOption, FilterOptions(state: .downloading))
    }

    func test_labelSelected_shouldEmitAlert() {
        var alert: Alert?
        viewModel.events.first().sink { event in
            guard case let .alert(inner, _) = event else { return }
            alert = inner
        }.store(in: &observers)
        viewModel.handle(.labelSelected(source: .view(UIView(), rect: .zero)))
        XCTAssertEqual(alert?.actions.map { $0.title }, ["All", "None", "test", "Cancel"])
    }

    func test_labelSelected_whenAllSelected_shouldRemoveLabelFilter() {
        var alert: Alert?
        viewModel.events.first().sink { event in
            guard case let .alert(inner, _) = event else { return }
            alert = inner
        }.store(in: &observers)
        viewModel.handle(.labelSelected(source: .view(UIView(), rect: .zero)))
        alert?.actions.first { $0.title == "All" }?.handler?()
        let newOption = preferences.value(for: PreferenceKeys.filterOptions)
        XCTAssertEqual(newOption, FilterOptions())
    }

    func test_labelSelected_whenNoneSelected_shouldSetEmptyLabel() {
        var alert: Alert?
        viewModel.events.first().sink { event in
            guard case let .alert(inner, _) = event else { return }
            alert = inner
        }.store(in: &observers)
        viewModel.handle(.labelSelected(source: .view(UIView(), rect: .zero)))
        alert?.actions.first { $0.title == "None" }?.handler?()
        let newOption = preferences.value(for: PreferenceKeys.filterOptions)
        XCTAssertEqual(newOption, FilterOptions(label: ""))
    }

    func test_labelSelected_withNewOption_shouldSetNewOption() {
        var alert: Alert?
        viewModel.events.first().sink { event in
            guard case let .alert(inner, _) = event else { return }
            alert = inner
        }.store(in: &observers)
        viewModel.handle(.labelSelected(source: .view(UIView(), rect: .zero)))
        alert?.actions.first { $0.title == "test" }?.handler?()
        let newOption = preferences.value(for: PreferenceKeys.filterOptions)
        XCTAssertEqual(newOption, FilterOptions(label: "test"))
    }
}
