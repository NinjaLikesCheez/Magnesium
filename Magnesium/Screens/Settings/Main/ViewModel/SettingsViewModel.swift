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
    func didSelectChangeServer(from source: PopoverSource)
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
    private let session: Session
    private let preferences: Preferences
    private var observers = [AnyCancellable]()
    private var sectionsSubject = CurrentValueSubject<[SettingsSection], Never>([])
    private(set) weak var coordinator: SettingsCoordinator?

    var sections: AnyPublisher<[SettingsSection], Never> {
        return sectionsSubject
            .ui()
            .eraseToAnyPublisher()
    }

    init(coordinator: SettingsCoordinator, session: Session, preferences: Preferences) {
        self.coordinator = coordinator
        self.session = session
        self.preferences = preferences

        preferences.valueUpdatedPublisher(for: PreferenceKeys.servers)
            .sink { [weak self] _ in
                self?.updateSections()
            }
            .store(in: &observers)

        session.serverPublisher
            .dropFirst()
            .sink { [weak self] _ in
                self?.updateSections()
            }
            .store(in: &observers)

        updateSections()
    }

    private func updateSections() {
        let servers = preferences.getServers()
        var sections = [SettingsSection]()

        if servers.count > 1, let server = session.server {
            sections.append(SettingsSection(type: .changeServer, items: [.changeServer(server.name)]))
        }

        let serverItems = servers.map { SettingsItem.server(id: $0.id, name: $0.name) }
        sections.append(SettingsSection(type: .servers, items: serverItems + [.addServer]))
        sectionsSubject.send(sections)
    }

    func didSelectChangeServer(from source: PopoverSource) {
        let servers = preferences.getServers()
        var alert = Alert(title: nil, message: nil, style: .actionSheet)
        for server in servers {
            alert.actions.append(AlertAction(title: server.name, style: .default, handler: { [weak self] in
                self?.session.setServer(server)
            }))
        }
        alert.actions.append(AlertAction(title: "Cancel", style: .cancel, handler: nil))
        coordinator?.showAlert(alert, from: source)
    }

    func didSelectServer(at index: Int) {
        let server = preferences.getServers()[index]
        coordinator?.showServerSettings(server)
    }

    func didSelectAddServer() {
        coordinator?.showAddServer()
    }
}
