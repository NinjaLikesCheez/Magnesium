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
        let mappedLabels = CurrentValueSubject<[StandardLabel], Never>(labelsSubject.value)
        labelsSubject.sink { [weak mappedLabels] in mappedLabels?.send($0) }.store(in: &cancellables)
        viewModel = FilterViewModel(labels: mappedLabels.eraseToAnyPublisher())
    }

    func test_sections_withoutLabels_shouldEmitExpectedValues() throws {
        labelsSubject.send([])
        let sections = try viewModel.values.sections.first().wait().singleValue()
        let expected = [
            FilterSection(type: .sort, items: [.sort("↓ Date Added")]),
            FilterSection(type: .filters, items: [.state("All")]),
        ]
        XCTAssertEqual(sections, expected)
    }

    func test_sections_withLabels_shouldEmitExpectedValues() throws {
        let sections = try viewModel.values.sections.first().wait().singleValue()
        let expected = [
            FilterSection(type: .sort, items: [.sort("↓ Date Added")]),
            FilterSection(type: .filters, items: [.state("All"), .label("All")]),
        ]
        XCTAssertEqual(sections, expected)
    }

    func test_sections_whenSortOptionChanged_shouldEmitNewSections() throws {
        let sections = try viewModel.values.sections.dropFirst().first().wait {
            self.preferences[.sortOption] = SortOption(property: .name)
        }.singleValue()
        XCTAssertEqual(sections[0].items, [.sort("↑ Name")])
    }

    func test_sections_whenFilterOptionsChanged_shouldEmit() throws {
        let sections = try viewModel.values.sections.dropFirst().first().wait {
            self.preferences[.filterOptions] = FilterOptions(state: .downloading)
        }.singleValue()
        XCTAssertEqual(sections[1].items[0], .state("Downloading"))
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
        let expected = ["Date Added", "Name", "Download Speed", "Upload Speed", "Cancel"]
        let event = try viewModel.eventPublisher.first().wait {
            self.viewModel.send(.sortSelected(source: .view(UIView(), rect: .zero)))
        }.singleValue()
        let alert = try extract(case: type(of: event).alert, from: event)
        XCTAssertEqual(alert.actions.map(\.title), expected)
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
        alert.actions.first { $0.title == "Name" }?.handler?()
        let newOption = preferences[.sortOption]
        XCTAssertEqual(newOption, SortOption(property: .name))
    }

    func test_stateSelected_shouldEmitAlert() throws {
        let event = try viewModel.eventPublisher.first().wait {
            self.viewModel.send(.stateSelected(source: .view(UIView(), rect: .zero)))
        }.singleValue()
        let alert = try extract(case: type(of: event).alert, from: event)
        let expected = ["All", "Downloading", "Seeding", "Paused", "Checking", "Queued", "Error", "Cancel"]
        XCTAssertEqual(alert.actions.map(\.title), expected)
    }

    func test_stateSelected_withNewOption_shouldSetNewOption() throws {
        let event = try viewModel.eventPublisher.first().wait {
            self.viewModel.send(.stateSelected(source: .view(UIView(), rect: .zero)))
        }.singleValue()
        let alert = try extract(case: type(of: event).alert, from: event)
        alert.actions.first { $0.title == "Downloading" }?.handler?()
        let newOption = preferences[.filterOptions]
        XCTAssertEqual(newOption, FilterOptions(state: .downloading))
    }

    func test_labelSelected_shouldEmitAlert() throws {
        let event = try viewModel.eventPublisher.first().wait {
            self.viewModel.send(.labelSelected(source: .view(UIView(), rect: .zero)))
        }.singleValue()
        let alert = try extract(case: type(of: event).alert, from: event)
        XCTAssertEqual(alert.actions.map(\.title), ["All", "None", "test", "Cancel"])
    }

    func test_labelSelected_whenAllSelected_shouldRemoveLabelFilter() throws {
        let event = try viewModel.eventPublisher.first().wait {
            self.viewModel.send(.labelSelected(source: .view(UIView(), rect: .zero)))
        }.singleValue()
        let alert = try extract(case: type(of: event).alert, from: event)
        alert.actions.first { $0.title == "All" }?.handler?()
        let newOption = preferences[.filterOptions]
        XCTAssertEqual(newOption, FilterOptions())
    }

    func test_labelSelected_whenNoneSelected_shouldSetEmptyLabel() throws {
        let event = try viewModel.eventPublisher.first().wait {
            self.viewModel.send(.labelSelected(source: .view(UIView(), rect: .zero)))
        }.singleValue()
        let alert = try extract(case: type(of: event).alert, from: event)
        alert.actions.first { $0.title == "None" }?.handler?()
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
