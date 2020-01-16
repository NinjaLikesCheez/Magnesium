//
//  DefaultAddServerViewModel.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-15.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Navigator
import Preferences

final class DefaultAddServerViewModel: AddServerViewModel {
    private let navigator: Navigator
    private let preferences: Preferences

    private var serverTypes: [ServerType] = [
        .deluge,
    ]

    var types: [String] {
        return serverTypes.map { $0.displayString }
    }

    init(navigator: Navigator, preferences: Preferences) {
        self.navigator = navigator
        self.preferences = preferences
    }

    func didSelectType(at index: Int) {
        switch serverTypes[index] {
        case .deluge:
            let viewModel = DefaultDelugeSettingsViewModel(navigator: navigator, preferences: preferences)
            navigator.push(Screens.delugeSettings(viewModel: viewModel), animated: true)
        }
    }
}
