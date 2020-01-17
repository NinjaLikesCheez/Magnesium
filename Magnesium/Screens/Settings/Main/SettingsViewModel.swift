//
//  SettingsViewModel.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-14.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import Preferences

protocol SettingsViewModel {
    var coordinator: SettingsCoordinator? { get }
    var servers: AnyPublisher<[(id: AnyHashable, name: String)], Never> { get }
    func didSelectClose()
    func didSelectServer(at index: Int)
    func didSelectAddServer()
}

extension SettingsViewModel {
    func didSelectClose() {
        coordinator?.complete()
    }
}

final class DefaultSettingsViewModel: SettingsViewModel {
    private let preferences: Preferences
    private var observers = [AnyCancellable]()
    private var serversSubject = CurrentValueSubject<[Server], Never>([])

    weak var coordinator: SettingsCoordinator?

    var servers: AnyPublisher<[(id: AnyHashable, name: String)], Never> {
        return serversSubject
            .map { $0.map { ($0.id, $0.name) } }
            .ui()
            .eraseToAnyPublisher()
    }

    init(coordinator: SettingsCoordinator, preferences: Preferences) {
        self.coordinator = coordinator
        self.preferences = preferences

        preferences.valuePublisher(for: PreferenceKeys.servers)
            .sink { [weak self] servers in
                self?.serversSubject.send(servers ?? [])
            }
            .store(in: &observers)
    }

    func didSelectServer(at index: Int) {
        let server = serversSubject.value[index]
        coordinator?.showServerSettings(server)
    }

    func didSelectAddServer() {
        coordinator?.showAddServer()
    }
}
