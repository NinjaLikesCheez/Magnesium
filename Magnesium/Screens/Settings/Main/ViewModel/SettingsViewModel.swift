//
//  SettingsViewModel.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-14.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import Preferences

enum SettingsEvent {
    case complete
    case selected(server: Server)
    case addServer
    case alert(Alert, source: PopoverSource?)
}

protocol SettingsViewModel {
    var events: AnyPublisher<SettingsEvent, Never> { get }
    var sections: AnyPublisher<[SettingsSection], Never> { get }
    func didSelectClose()
    func didSelectChangeServer(from source: PopoverSource)
    func didSelectServer(at index: Int)
    func didSelectAddServer()
}

final class DefaultSettingsViewModel: SettingsViewModel {
    private let session: Session
    private let preferences: Preferences
    private var observers = [AnyCancellable]()
    private let eventSubject = PassthroughSubject<SettingsEvent, Never>()
    private var sectionsSubject = CurrentValueSubject<[SettingsSection], Never>([])

    var events: AnyPublisher<SettingsEvent, Never> {
        return eventSubject.eraseToAnyPublisher()
    }

    var sections: AnyPublisher<[SettingsSection], Never> {
        return sectionsSubject
            .ui()
            .eraseToAnyPublisher()
    }

    init(session: Session, preferences: Preferences) {
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

    func didSelectClose() {
        eventSubject.send(.complete)
    }

    func didSelectChangeServer(from source: PopoverSource) {
        let servers = preferences.getServers()
        var alert = Alert(title: nil, message: nil, style: .actionSheet)
        for server in servers {
            alert.addAction(AlertAction(title: server.name, style: .default) {
                self.session.setServer(server)
            })
        }
        alert.addAction(AlertAction(title: "Cancel", style: .cancel))
        eventSubject.send(.alert(alert, source: source))
    }

    func didSelectServer(at index: Int) {
        let server = preferences.getServers()[index]
        eventSubject.send(.selected(server: server))
    }

    func didSelectAddServer() {
        eventSubject.send(.addServer)
    }
}
