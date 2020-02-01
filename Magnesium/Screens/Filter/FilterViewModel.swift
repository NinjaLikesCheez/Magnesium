//
//  FilterViewModel.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-30.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import Coordinator
import Preferences
import SwiftUI
import UIKit
import ViewModel

enum FilterEvent {
    case complete
    case alert(Alert, source: PopoverSource)
}

enum FilterViewEvent {
    case doneSelected
    case sortSelected(source: PopoverSource)
    case stateSelected(source: PopoverSource)
}

struct FilterViewState {
    var sortOption: AnyPublisher<String, Never>
    var state: AnyPublisher<String, Never>
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
        let state = preferences.valuePublisher(for: PreferenceKeys.filterOptions)
            .map(\.state)
            .map { $0?.displayString ?? "All" }
            .ui()
            .eraseToAnyPublisher()
        self.state = FilterViewState(sortOption: sortOption, state: state)
    }

    func handle(_ event: FilterViewEvent) {
        switch event {
        case .doneSelected:
            eventSubject.send(.complete)
        case let .sortSelected(source: source):
            guard let currentSort = try? preferences.value(for: PreferenceKeys.sortOption) else {
                return
            }

            var alert = Alert(title: nil, message: nil, style: .actionSheet)

            for property in SortOption.Property.allCases {
                alert.addAction(AlertAction(title: property.displayString, style: .default) {
                    if property == currentSort.property {
                        let sortOption = currentSort.withOppositeDirection()
                        _ = try? self.preferences.set(sortOption, for: PreferenceKeys.sortOption)
                    } else {
                        _ = try? self.preferences.set(SortOption(property: property), for: PreferenceKeys.sortOption)
                    }
                })
            }

            alert.addAction(AlertAction(title: "Cancel", style: .cancel))
            eventSubject.send(.alert(alert, source: source))
        case .stateSelected:
            // TODO:
            break
        }
    }
}
