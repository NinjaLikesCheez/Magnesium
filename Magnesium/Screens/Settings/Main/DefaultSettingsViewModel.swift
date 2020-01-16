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
        guard let navigator = navigator else {
            return
        }

        let server = serversSubject.value[index]
        switch server.type {
        case .deluge:
            let viewModel = DefaultDelugeSettingsViewModel(
                navigator: navigator,
                preferences: preferences,
                server: server
            )
            navigator.push(Screens.delugeSettings(viewModel: viewModel), animated: true)
        }
    }

    func didSelectAddServer() {
        guard let navigator = navigator else { return }
        let viewModel = DefaultAddServerViewModel(navigator: navigator, preferences: preferences)
        navigator.push(Screens.addServer(viewModel: viewModel), animated: true)
    }
}
