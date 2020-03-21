import Combine
import Preferences
import ViewModel

enum FilterEvent {
    case complete
    case alert(Alert)
}

enum FilterViewEvent {
    case doneSelected
    case sortSelected(source: PopoverSource)
    case stateSelected(source: PopoverSource)
    case labelSelected(source: PopoverSource)
}

struct FilterViewState {
    var sections: AnyPublisher<[FilterSection], Never>
}

final class FilterViewModel: ViewModel {
    private let labels: CurrentValueSubject<[StandardLabel], Never>
    private let eventSubject = PassthroughSubject<FilterEvent, Never>()
    private var sectionsSubject = CurrentValueSubject<[FilterSection], Never>([])
    private var cancellables = Set<AnyCancellable>()
    let state: FilterViewState

    var events: AnyPublisher<FilterEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    init(labels: CurrentValueSubject<[StandardLabel], Never>) {
        self.labels = labels
        state = FilterViewState(sections: sectionsSubject.eraseToAnyPublisher())

        Current.preferences.valueUpdatedPublisher(for: .sortOption)
            .map { _ in () }
            .merge(with: Current.preferences.valueUpdatedPublisher(for: .filterOptions).map { _ in () })
            .merge(with: labels.removeDuplicates(by: { $0.map(\.name) == $1.map(\.name) }).map { _ in () })
            .sink { [weak self] _ in
                self?.updateSections()
            }
            .store(in: &cancellables)

        updateSections()
    }

    func handle(_ event: FilterViewEvent) {
        switch event {
        case .doneSelected:
            eventSubject.send(.complete)
        case let .sortSelected(source):
            handleSortSelected(from: source)
        case let .stateSelected(source):
            handleStateSelected(from: source)
        case let .labelSelected(source):
            handleLabelSelected(from: source)
        }
    }

    private func handleSortSelected(from source: PopoverSource) {
        let currentSort = Current.preferences[.sortOption]
        let sortActions = SortOption.Property.allCases.map { property in
            AlertAction(title: property.localizedString, style: .default) {
                if property == currentSort.property {
                    let sortOption = currentSort.withOppositeDirection()
                    Current.preferences[.sortOption] = sortOption
                } else {
                    Current.preferences[.sortOption] = SortOption(property: property)
                }
            }
        }
        let alert = Alert(
            title: L10n.sortByAlertTitle,
            message: L10n.sortByAlertMessage,
            style: .actionSheet(source),
            actions: sortActions + [.cancel]
        )
        eventSubject.send(.alert(alert))
    }

    private func handleLabelSelected(from source: PopoverSource) {
        var filterOptions = Current.preferences[.filterOptions]
        let labels: [StandardLabel?] = [nil] + self.labels.value
        let labelActions = labels.map { label in
            AlertAction(
                title: label.map(\.displayName) ?? L10n.allFilter,
                style: .default,
                handler: {
                    filterOptions.label = label?.name
                    Current.preferences[.filterOptions] = filterOptions
                }
            )
        }

        let alert = Alert(
            title: L10n.filterLabelAlertTitle,
            message: L10n.filterLabelAlertMessage,
            style: .actionSheet(source),
            actions: labelActions + [.cancel]
        )
        eventSubject.send(.alert(alert))
    }

    private func handleStateSelected(from source: PopoverSource) {
        var filterOptions = Current.preferences[.filterOptions]
        let states: [TorrentState?] = [nil] + TorrentState.allCases
        let filterActions = states.map { state in
            AlertAction(
                title: state?.localizedString ?? L10n.allFilter,
                style: .default,
                handler: {
                    filterOptions.state = state
                    Current.preferences[.filterOptions] = filterOptions
                }
            )
        }
        let alert = Alert(
            title: L10n.filterStateAlertTitle,
            message: L10n.filterStateAlertMessage,
            style: .actionSheet(source),
            actions: filterActions + [.cancel]
        )
        eventSubject.send(.alert(alert))
    }

    private func updateSections() {
        let sortOption = Current.preferences[.sortOption]
        let filterOptions = Current.preferences[.filterOptions]
        var sections = [FilterSection]()

        sections.append(FilterSection(type: .sort, items: [
            .sort(sortOption.localizedString),
        ]))

        var filtersSection = FilterSection(type: .filters, items: [
            .state(filterOptions.state?.localizedString ?? L10n.allFilter),
        ])

        if !labels.value.isEmpty {
            let labelName = filterOptions.label.map {
                $0.isEmpty ? L10n.noneLabel : $0
            }
            filtersSection.items.append(.label(labelName ?? L10n.allFilter))
        }

        sections.append(filtersSection)
        sectionsSubject.send(sections)
    }
}
