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
    case filterStateSelected(source: PopoverSource)
}

struct FilterViewState {
    var sortOption: AnyPublisher<String, Never>
    var filterState: AnyPublisher<String, Never>
}

final class FilterViewModel: ViewModel, EventEmitter {
    private let preferences: Preferences
    private let eventSubject = PassthroughSubject<FilterEvent, Never>()
    let state: FilterViewState

    var events: AnyPublisher<FilterEvent, Never> {
        return eventSubject.eraseToAnyPublisher()
    }

    init(preferences: Preferences) {
        self.preferences = preferences
        let sortOption = preferences.valuePublisher(for: PreferenceKeys.sortOption)
            .map(\.displayString)
            .ui()
            .eraseToAnyPublisher()
        let filterState = preferences.valuePublisher(for: PreferenceKeys.filterOptions)
            .map(\.state)
            .map { $0?.displayString ?? "All" }
            .ui()
            .eraseToAnyPublisher()
        state = FilterViewState(sortOption: sortOption, filterState: filterState)
    }

    func handle(_ event: FilterViewEvent) {
        switch event {
        case .doneSelected:
            eventSubject.send(.complete)
        case let .sortSelected(source: source):
            handleSortSelected(from: source)
        case let .filterStateSelected(source: source):
            handleFilterStateSelected(from: source)
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

    private func handleFilterStateSelected(from source: PopoverSource) {
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
}
