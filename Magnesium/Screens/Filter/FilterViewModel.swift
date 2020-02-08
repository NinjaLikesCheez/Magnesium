//
//  FilterViewModel.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-30.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
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

        preferences.valueUpdatedPublisher(for: PreferenceKeys.sortOption).map { _ in () }
            .merge(with: preferences.valueUpdatedPublisher(for: PreferenceKeys.filterOptions).map { _ in () })
            .merge(with: labels.removeDuplicates(by: { $0.map { $0.name } == $1.map { $0.name } }).map { _ in () })
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
        var alert = Alert(
            title: "Sort by",
            message: "Select the current sort option to sort in the opposite direction.",
            style: .actionSheet
        )

        for property in SortOption.Property.allCases {
            alert.addAction(AlertAction(title: property.displayString, style: .default) {
                if property == currentSort.property {
                    let sortOption = currentSort.withOppositeDirection()
                    self.preferences.set(sortOption, for: PreferenceKeys.sortOption)
                } else {
                    self.preferences.set(SortOption(property: property), for: PreferenceKeys.sortOption)
                }
            })
        }

        alert.addAction(AlertAction(title: "Cancel", style: .cancel))
        eventSubject.send(.alert(alert, source: source))
    }

    private func handleLabelSelected(from source: PopoverSource) {
        var filterOptions = preferences.value(for: PreferenceKeys.filterOptions)
        var alert = Alert(
            title: "Filter by Label",
            message: "Only display torrents with the selected label.",
            style: .actionSheet
        )
        let labels: [StandardLabel?] = [nil] + self.labels.value

        for label in labels {
            let displayName = label.map { $0.displayName } ?? "All"
            alert.addAction(AlertAction(title: displayName, style: .default) {
                filterOptions.label = label?.name
                self.preferences.set(filterOptions, for: PreferenceKeys.filterOptions)
            })
        }

        alert.addAction(AlertAction(title: "Cancel", style: .cancel))
        eventSubject.send(.alert(alert, source: source))
    }

    private func handleStateSelected(from source: PopoverSource) {
        var filterOptions = preferences.value(for: PreferenceKeys.filterOptions)
        var alert = Alert(
            title: "Filter by State",
            message: "Only display torrents with the selected state.",
            style: .actionSheet
        )
        let states: [TorrentState?] = [nil] + TorrentState.allCases

        for state in states {
            alert.addAction(AlertAction(title: state?.displayString ?? "All", style: .default) {
                filterOptions.state = state
                self.preferences.set(filterOptions, for: PreferenceKeys.filterOptions)
            })
        }

        alert.addAction(AlertAction(title: "Cancel", style: .cancel))
        eventSubject.send(.alert(alert, source: source))
    }

    private func updateSections() {
        let sortOption = preferences.value(for: PreferenceKeys.sortOption)
        let filterOptions = preferences.value(for: PreferenceKeys.filterOptions)
        var sections = [FilterSection]()

        sections.append(FilterSection(type: .sort, items: [
            .sort(sortOption.displayString),
        ]))

        var filtersSection = FilterSection(type: .filters, items: [
            .state(filterOptions.state?.displayString ?? "All"),
        ])

        if !labels.value.isEmpty {
            filtersSection.items.append(.label(filterOptions.label.map { $0.isEmpty ? "None" : $0 } ?? "All"))
        }

        sections.append(filtersSection)
        sectionsSubject.send(sections)
    }
}
