import Combine
import CommonModels
@testable import Magnesium
import Preferences
import XCTest

class FilterViewModelTests: TestCase {
    private var labelsSubject: CurrentValueSubject<[StandardLabel], Never>!
    private var viewModel: FilterViewModel!
    private var cancellables: Set<AnyCancellable>!
    private var preferences: Preferences { Current.preferences }

    override func setUp() {
        super.setUp()
        labelsSubject = CurrentValueSubject([.mock(), .mock(name: "test")])
        cancellables = Set()
        viewModel = FilterViewModel(labels: labelsSubject.eraseToAnyPublisher())
    }

    func test_sections_withoutLabels_shouldEmitExpectedValues() throws {
        labelsSubject.send([])
        let sections = try viewModel.values.sections.first().wait().singleValue()
        let expected = [
            FilterSection(type: .sort, items: [.sort(L10n.Sort.descending(property: L10n.Sort.dateAdded))]),
            FilterSection(type: .filters, items: [.state(L10n.Screen.Filter.filteredAll)]),
        ]
        XCTAssertEqual(sections, expected)
    }

    func test_sections_withLabels_shouldEmitExpectedValues() throws {
        let sections = try viewModel.values.sections.first().wait().singleValue()
        let expected = [
            FilterSection(type: .sort, items: [.sort(L10n.Sort.descending(property: L10n.Sort.dateAdded))]),
            FilterSection(type: .filters, items: [
                .state(L10n.Screen.Filter.filteredAll),
                .label(L10n.Screen.Filter.filteredAll),
            ]),
        ]
        XCTAssertEqual(sections, expected)
    }

    func test_sections_whenSortOptionChanged_shouldEmitNewSections() throws {
        let sections = try viewModel.values.sections.dropFirst().first().wait {
            self.preferences[.sortOption] = SortOption(property: .name)
        }.singleValue()
        XCTAssertEqual(sections[0].items, [.sort(L10n.Sort.ascending(property: L10n.Sort.name))])
    }

    func test_sections_whenFilterOptionsChanged_shouldEmit() throws {
        let sections = try viewModel.values.sections.dropFirst().first().wait {
            self.preferences[.filterOptions] = FilterOptions(state: .downloading)
        }.singleValue()
        XCTAssertEqual(sections[1].items[0], .state(L10n.Torrent.downloadingState))
    }

    func test_sections_whenLabelsUpdated_shouldEmit() {
        let sections = viewModel.values.sections.dropFirst().first().wait {
            self.labelsSubject.send(self.labelsSubject.value + [.mock(name: "new")])
        }
        XCTAssertFalse(sections.values().isEmpty)
    }

    func test_sections_withSameLabelsPublished_shouldNotEmit() {
        labelsSubject.send(labelsSubject.value)
        let sections = viewModel.values.sections.dropFirst().first().wait {
            self.labelsSubject.send(self.labelsSubject.value)
        }
        XCTAssertTrue(sections.values().isEmpty)
    }

    func test_doneSelected_shouldEmitCompleteEvent() throws {
        let event = try viewModel.eventPublisher.first().wait {
            self.viewModel.send(.doneSelected)
        }.singleValue()
        XCTAssertCase(event, .complete)
    }

    func test_sortSelected_shouldEmitAlert() throws {
        let event = try viewModel.eventPublisher.first().wait {
            self.viewModel.send(.sortSelected(source: .view(UIView(), rect: .zero)))
        }.singleValue()
        let alert = try extract(case: type(of: event).alert, from: event)
        XCTAssertEqual(alert.actions.map(\.title), [
            L10n.Sort.dateAdded,
            L10n.Sort.name,
            L10n.Sort.downloadSpeed,
            L10n.Sort.uploadSpeed,
            L10n.Action.cancel,
        ])
    }

    func test_sortSelected__whenExistingOptionSelected_shouldInvert() throws {
        let event = try viewModel.eventPublisher.first().wait {
            self.viewModel.send(.sortSelected(source: .view(UIView(), rect: .zero)))
        }.singleValue()
        let alert = try extract(case: type(of: event).alert, from: event)
        let previousOption = preferences[.sortOption]
        alert.actions.first { $0.title == previousOption.property.localizedString }?.handler?()
        let newOption = preferences[.sortOption]
        XCTAssertEqual(newOption, previousOption.withOppositeDirection())
    }

    func test_sortSelected_withNewOption_shouldSetNewOption() throws {
        let event = try viewModel.eventPublisher.first().wait {
            self.viewModel.send(.sortSelected(source: .view(UIView(), rect: .zero)))
        }.singleValue()
        let alert = try extract(case: type(of: event).alert, from: event)
        alert.actions.first { $0.title == L10n.Sort.name }?.handler?()
        let newOption = preferences[.sortOption]
        XCTAssertEqual(newOption, SortOption(property: .name))
    }

    func test_stateSelected_shouldEmitAlert() throws {
        let event = try viewModel.eventPublisher.first().wait {
            self.viewModel.send(.stateSelected(source: .view(UIView(), rect: .zero)))
        }.singleValue()
        let alert = try extract(case: type(of: event).alert, from: event)
        XCTAssertEqual(alert.actions.map(\.title), [
            L10n.Screen.Filter.filteredAll,
            L10n.Torrent.downloadingState,
            L10n.Torrent.seedingState,
            L10n.Torrent.pausedState,
            L10n.Torrent.checkingState,
            L10n.Torrent.queuedState,
            L10n.Torrent.errorState,
            L10n.Action.cancel,
        ])
    }

    func test_stateSelected_withNewOption_shouldSetNewOption() throws {
        let event = try viewModel.eventPublisher.first().wait {
            self.viewModel.send(.stateSelected(source: .view(UIView(), rect: .zero)))
        }.singleValue()
        let alert = try extract(case: type(of: event).alert, from: event)
        alert.actions.first { $0.title == L10n.Torrent.downloadingState }?.handler?()
        let newOption = preferences[.filterOptions]
        XCTAssertEqual(newOption, FilterOptions(state: .downloading))
    }

    func test_labelSelected_shouldEmitAlert() throws {
        let event = try viewModel.eventPublisher.first().wait {
            self.viewModel.send(.labelSelected(source: .view(UIView(), rect: .zero)))
        }.singleValue()
        let alert = try extract(case: type(of: event).alert, from: event)
        XCTAssertEqual(alert.actions.map(\.title), [
            L10n.Screen.Filter.filteredAll,
            L10n.Label.none,
            "test",
            L10n.Action.cancel,
        ])
    }

    func test_labelSelected_whenAllSelected_shouldRemoveLabelFilter() throws {
        let event = try viewModel.eventPublisher.first().wait {
            self.viewModel.send(.labelSelected(source: .view(UIView(), rect: .zero)))
        }.singleValue()
        let alert = try extract(case: type(of: event).alert, from: event)
        alert.actions.first { $0.title == L10n.Screen.Filter.filteredAll }?.handler?()
        let newOption = preferences[.filterOptions]
        XCTAssertEqual(newOption, FilterOptions())
    }

    func test_labelSelected_whenNoneSelected_shouldSetEmptyLabel() throws {
        let event = try viewModel.eventPublisher.first().wait {
            self.viewModel.send(.labelSelected(source: .view(UIView(), rect: .zero)))
        }.singleValue()
        let alert = try extract(case: type(of: event).alert, from: event)
        alert.actions.first { $0.title == L10n.Label.none }?.handler?()
        let newOption = preferences[.filterOptions]
        XCTAssertEqual(newOption, FilterOptions(label: ""))
    }

    func test_labelSelected_withNewOption_shouldSetNewOption() throws {
        let event = try viewModel.eventPublisher.first().wait {
            self.viewModel.send(.labelSelected(source: .view(UIView(), rect: .zero)))
        }.singleValue()
        let alert = try extract(case: type(of: event).alert, from: event)
        alert.actions.first { $0.title == "test" }?.handler?()
        let newOption = preferences[.filterOptions]
        XCTAssertEqual(newOption, FilterOptions(label: "test"))
    }
}
