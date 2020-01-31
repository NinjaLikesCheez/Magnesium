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
}

enum FilterViewEvent {
    case doneSelected
    case sortSelected
    case stateSelected
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
        case .sortSelected:
            // TODO:
            break
        case .stateSelected:
            // TODO:
            break
        }
    }
}
