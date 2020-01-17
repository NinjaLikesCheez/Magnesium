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
    var sections: AnyPublisher<[SettingsSection], Never> { get }
    func didSelectChangeServer()
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
    private var sectionsSubject = CurrentValueSubject<[SettingsSection], Never>([])

    weak var coordinator: SettingsCoordinator?

    var sections: AnyPublisher<[SettingsSection], Never> {
        return sectionsSubject
            .ui()
            .eraseToAnyPublisher()
    }

    init(coordinator: SettingsCoordinator, preferences: Preferences) {
        self.coordinator = coordinator
        self.preferences = preferences

        preferences.valueUpdatedPublisher(for: PreferenceKeys.servers)
            .sink { [weak self] _ in
                self?.updateSections()
            }
            .store(in: &observers)

        updateSections()
    }

    private func updateSections() {
        let servers = preferences.getServers()
        var sections = [SettingsSection]()

        if servers.count > 1 {
            sections.append(SettingsSection(type: .changeServer, items: [.changeServer(servers[0].name)]))
        }

        let serverItems = servers.map { SettingsItem.server(id: $0.id, name: $0.name) }
        sections.append(SettingsSection(type: .servers, items: serverItems + [.addServer]))
        sectionsSubject.send(sections)
    }

    func didSelectChangeServer() {
        // TODO:
    }

    func didSelectServer(at index: Int) {
        let server = preferences.getServers()[index]
        coordinator?.showServerSettings(server)
    }

    func didSelectAddServer() {
        coordinator?.showAddServer()
    }
}
