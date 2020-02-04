//
//  RefreshIntervalViewModel.swift
//  Magnesium
//
//  Created by James Hurst on 2020-02-03.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import Foundation
import Preferences
import ViewModel

enum RefreshIntervalViewEvent {
    case optionSelected(index: Int)
}

struct RefreshIntervalViewState {
    var options: [RefreshIntervalOptionViewState]
}

struct RefreshIntervalOptionViewState {
    var name: String
    var isSelected: AnyPublisher<Bool, Never>
}

final class RefreshIntervalViewModel: ViewModel {
    private let preferences: Preferences
    let state: RefreshIntervalViewState

    private let options: [(Int, String)] = [
        (0, "Never"),
        (2, "2 seconds"),
        (5, "5 seconds"),
    ]

    init(preferences: Preferences) {
        self.preferences = preferences
        let publisher = preferences.valuePublisher(for: PreferenceKeys.autoRefreshInterval).ui()
        state = RefreshIntervalViewState(options: options.map { option in
            RefreshIntervalOptionViewState(
                name: option.1,
                isSelected: publisher.map { Int($0) == option.0 }.eraseToAnyPublisher()
            )
        })
    }

    func handle(_ event: RefreshIntervalViewEvent) {
        switch event {
        case let .optionSelected(index: index):
            let interval = options[index].0
            preferences.set(TimeInterval(interval), for: PreferenceKeys.autoRefreshInterval)
        }
    }
}
