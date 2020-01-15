//
//  DefaultSettingsViewModel.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-14.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import Navigator
import Preferences

final class DefaultSettingsViewModel: SettingsViewModel {
    private var observers = [AnyCancellable]()
    private var serversSubject = CurrentValueSubject<[Server], Never>([])

    var servers: AnyPublisher<[(id: AnyHashable, name: String)], Never> {
        return serversSubject
            .map { $0.map { ($0.id, $0.name) } }
            .ui()
            .eraseToAnyPublisher()
    }

    private let preferences: Preferences
    var navigator: Navigator?

    init(preferences: Preferences) {
        self.preferences = preferences

        preferences.valuePublisher(for: PreferenceKeys.servers)
            .sink { [weak self] servers in
                self?.serversSubject.send(servers ?? [])
            }
            .store(in: &observers)
    }

    func didSelectClose() {
        navigator?.dismiss(animated: true)
    }

    func didSelectServer(at index: Int) {
        // TODO: display server settings
        preferences.remove(server: serversSubject.value[index])
    }

    func didSelectAddServer() {
        // TODO: actually display server selection
        guard let navigator = navigator else { return }
        let viewModel = DefaultDelugeSettingsViewModel(navigator: navigator, preferences: preferences)
        navigator.push(Screens.delugeSettings(viewModel: viewModel), animated: true)
    }
}
