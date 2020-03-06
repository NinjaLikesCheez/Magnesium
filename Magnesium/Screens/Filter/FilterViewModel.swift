import Combine
import Foundation
import Preferences
import ViewModel

enum FilterEvent {
    case complete
    case alert(Alert, source: PopoverSource)
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

final class FilterViewModel: ViewModel, EventEmitter {
    private let preferences: Preferences
    private let labels: CurrentValueSubject<[StandardLabel], Never>
    private let eventSubject = PassthroughSubject<FilterEvent, Never>()
    private var sectionsSubject = CurrentValueSubject<[FilterSection], Never>([])
    private var observers = [AnyCancellable]()
    let state: FilterViewState

    var events: AnyPublisher<FilterEvent, Never> {
        return eventSubject.eraseToAnyPublisher()
    }

    init(preferences: Preferences, labels: CurrentValueSubject<[StandardLabel], Never>) {
        self.preferences = preferences
        self.labels = labels
        state = FilterViewState(sections: sectionsSubject.eraseToAnyPublisher())

        preferences.valueUpdatedPublisher(for: PreferenceKeys.sortOption)
            .map { _ in () }
            .merge(with: preferences.valueUpdatedPublisher(for: PreferenceKeys.filterOptions).map { _ in () })
            .merge(with: labels.removeDuplicates(by: { $0.map(\.name) == $1.map(\.name) }).map { _ in () })
            .sink { [weak self] _ in
                self?.updateSections()
            }
            .store(in: &observers)

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
        let currentSort = preferences.value(for: PreferenceKeys.sortOption)
        var alert = Alert(title: L10n.sortByAlertTitle, message: L10n.sortByAlertMessage, style: .actionSheet)

        for property in SortOption.Property.allCases {
            alert.addAction(AlertAction(title: property.localizedString, style: .default) {
                if property == currentSort.property {
                    let sortOption = currentSort.withOppositeDirection()
                    self.preferences.set(sortOption, for: PreferenceKeys.sortOption)
                } else {
                    self.preferences.set(SortOption(property: property), for: PreferenceKeys.sortOption)
                }
            })
        }

        alert.addAction(.cancel)
        eventSubject.send(.alert(alert, source: source))
    }

    private func handleLabelSelected(from source: PopoverSource) {
        var filterOptions = preferences.value(for: PreferenceKeys.filterOptions)
        var alert = Alert(title: L10n.filterLabelAlertTitle, message: L10n.filterLabelAlertMessage, style: .actionSheet)
        let labels: [StandardLabel?] = [nil] + self.labels.value

        for label in labels {
            alert.addAction(AlertAction(
                title: label.map(\.displayName) ?? L10n.allFilter,
                style: .default,
                handler: {
                    filterOptions.label = label?.name
                    self.preferences.set(filterOptions, for: PreferenceKeys.filterOptions)
                }
            ))
        }

        alert.addAction(.cancel)
        eventSubject.send(.alert(alert, source: source))
    }

    private func handleStateSelected(from source: PopoverSource) {
        var filterOptions = preferences.value(for: PreferenceKeys.filterOptions)
        var alert = Alert(title: L10n.filterStateAlertTitle, message: L10n.filterStateAlertMessage, style: .actionSheet)
        let states: [TorrentState?] = [nil] + TorrentState.allCases

        for state in states {
            alert.addAction(AlertAction(
                title: state?.localizedString ?? L10n.allFilter,
                style: .default,
                handler: {
                    filterOptions.state = state
                    self.preferences.set(filterOptions, for: PreferenceKeys.filterOptions)
                }
            ))
        }

        alert.addAction(.cancel)
        eventSubject.send(.alert(alert, source: source))
    }

    private func updateSections() {
        let sortOption = preferences.value(for: PreferenceKeys.sortOption)
        let filterOptions = preferences.value(for: PreferenceKeys.filterOptions)
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
