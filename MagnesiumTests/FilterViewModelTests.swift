import Combine
import CommonModels
@testable import Magnesium
import Preferences
import XCTest

class FilterViewModelTests: TestCase {
    private var labels: CurrentValueSubject<[MockLabel], Never>!
    private var viewModel: FilterViewModel!
    private var cancellables: Set<AnyCancellable>!
    private var preferences: Preferences { Current.preferences }

    override func setUp() {
        super.setUp()
        labels = CurrentValueSubject([MockLabel(), MockLabel(name: "test")])
        cancellables = Set()
        let mappedLabels = CurrentValueSubject<[StandardLabel], Never>(labels.value)
        labels.sink { [weak mappedLabels] in mappedLabels?.send($0) }.store(in: &cancellables)
        viewModel = FilterViewModel(labels: mappedLabels)
    }

    func test_sections_withoutLabels_shouldEmitExpectedValues() throws {
        labels.send([])
        let sections = try viewModel.view.sections.first().wait().value()
        let expected = [
            FilterSection(type: .sort, items: [.sort("↓ Date Added")]),
            FilterSection(type: .filters, items: [.state("All")]),
        ]
        XCTAssertEqual(sections, expected)
    }

    func test_sections_withLabels_shouldEmitExpectedValues() throws {
        let sections = try viewModel.view.sections.first().wait().value()
        let expected = [
            FilterSection(type: .sort, items: [.sort("↓ Date Added")]),
            FilterSection(type: .filters, items: [.state("All"), .label("All")]),
        ]
        XCTAssertEqual(sections, expected)
    }

    func test_sections_whenSortOptionChanged_shouldEmitNewSections() throws {
        let sections = try viewModel.view.sections.dropFirst().first().wait {
            self.preferences[.sortOption] = SortOption(property: .name)
        }.value()
        XCTAssertEqual(sections[0].items, [.sort("↑ Name")])
    }

    func test_sections_whenFilterOptionsChanged_shouldEmit() throws {
        let sections = try viewModel.view.sections.dropFirst().first().wait {
            self.preferences[.filterOptions] = FilterOptions(state: .downloading)
        }.value()
        XCTAssertEqual(sections[1].items[0], .state("Downloading"))
    }

    func test_sections_whenLabelsUpdated_shouldEmit() {
        let sections = viewModel.view.sections.dropFirst().first().wait {
            self.labels.send(self.labels.value + [MockLabel(name: "new")])
        }
        XCTAssertTrue(sections.hasValue())
    }

    func test_sections_withSameLabelsPublished_shouldNotEmit() {
        labels.send(labels.value)
        let sections = viewModel.view.sections.dropFirst().first().wait {
            self.labels.send(self.labels.value)
        }
        XCTAssertFalse(sections.hasValue())
    }

    func test_doneSelected_shouldEmitCompleteEvent() throws {
        let event = try viewModel.events.first().wait {
            self.viewModel.receive(.doneSelected)
        }.value()
        XCTAssertCase(event, .complete)
    }

    func test_sortSelected_shouldEmitAlert() throws {
        let expected = ["Date Added", "Name", "Download Speed", "Upload Speed", "Cancel"]
        let event = try viewModel.events.first().wait {
            self.viewModel.receive(.sortSelected(source: .view(UIView(), rect: .zero)))
        }.value()
        let alert = try extract(case: type(of: event).alert, from: event)
        XCTAssertEqual(alert.actions.map(\.title), expected)
    }

    func test_sortSelected__whenExistingOptionSelected_shouldInvert() throws {
        let event = try viewModel.events.first().wait {
            self.viewModel.receive(.sortSelected(source: .view(UIView(), rect: .zero)))
        }.value()
        let alert = try extract(case: type(of: event).alert, from: event)
        let previousOption = preferences[.sortOption]
        alert.actions.first { $0.title == previousOption.property.localizedString }?.handler?()
        let newOption = preferences[.sortOption]
        XCTAssertEqual(newOption, previousOption.withOppositeDirection())
    }

    func test_sortSelected_withNewOption_shouldSetNewOption() throws {
        let event = try viewModel.events.first().wait {
            self.viewModel.receive(.sortSelected(source: .view(UIView(), rect: .zero)))
        }.value()
        let alert = try extract(case: type(of: event).alert, from: event)
        alert.actions.first { $0.title == "Name" }?.handler?()
        let newOption = preferences[.sortOption]
        XCTAssertEqual(newOption, SortOption(property: .name))
    }

    func test_stateSelected_shouldEmitAlert() throws {
        let event = try viewModel.events.first().wait {
            self.viewModel.receive(.stateSelected(source: .view(UIView(), rect: .zero)))
        }.value()
        let alert = try extract(case: type(of: event).alert, from: event)
        let expected = ["All", "Downloading", "Seeding", "Paused", "Checking", "Queued", "Error", "Cancel"]
        XCTAssertEqual(alert.actions.map(\.title), expected)
    }

    func test_stateSelected_withNewOption_shouldSetNewOption() throws {
        let event = try viewModel.events.first().wait {
            self.viewModel.receive(.stateSelected(source: .view(UIView(), rect: .zero)))
        }.value()
        let alert = try extract(case: type(of: event).alert, from: event)
        alert.actions.first { $0.title == "Downloading" }?.handler?()
        let newOption = preferences[.filterOptions]
        XCTAssertEqual(newOption, FilterOptions(state: .downloading))
    }

    func test_labelSelected_shouldEmitAlert() throws {
        let event = try viewModel.events.first().wait {
            self.viewModel.receive(.labelSelected(source: .view(UIView(), rect: .zero)))
        }.value()
        let alert = try extract(case: type(of: event).alert, from: event)
        XCTAssertEqual(alert.actions.map(\.title), ["All", "None", "test", "Cancel"])
    }

    func test_labelSelected_whenAllSelected_shouldRemoveLabelFilter() throws {
        let event = try viewModel.events.first().wait {
            self.viewModel.receive(.labelSelected(source: .view(UIView(), rect: .zero)))
        }.value()
        let alert = try extract(case: type(of: event).alert, from: event)
        alert.actions.first { $0.title == "All" }?.handler?()
        let newOption = preferences[.filterOptions]
        XCTAssertEqual(newOption, FilterOptions())
    }

    func test_labelSelected_whenNoneSelected_shouldSetEmptyLabel() throws {
        let event = try viewModel.events.first().wait {
            self.viewModel.receive(.labelSelected(source: .view(UIView(), rect: .zero)))
        }.value()
        let alert = try extract(case: type(of: event).alert, from: event)
        alert.actions.first { $0.title == "None" }?.handler?()
        let newOption = preferences[.filterOptions]
        XCTAssertEqual(newOption, FilterOptions(label: ""))
    }

    func test_labelSelected_withNewOption_shouldSetNewOption() throws {
        let event = try viewModel.events.first().wait {
            self.viewModel.receive(.labelSelected(source: .view(UIView(), rect: .zero)))
        }.value()
        let alert = try extract(case: type(of: event).alert, from: event)
        alert.actions.first { $0.title == "test" }?.handler?()
        let newOption = preferences[.filterOptions]
        XCTAssertEqual(newOption, FilterOptions(label: "test"))
    }
}
