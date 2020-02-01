//
//  SettingsViewModel.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-14.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import Preferences
import ViewModel

enum SettingsEvent {
    case complete
    case edit(server: Server)
    case addServer
    case alert(Alert, source: PopoverSource?)
    case advancedSettings
}

enum SettingsViewEvent {
    case doneSelected
    case changeServerSelected(source: PopoverSource)
    case serverSelected(index: Int)
    case addServerSelected
    case advancedSettingsSelected
}

struct SettingsViewState {
    var sections: AnyPublisher<[SettingsSection], Never>
}

final class SettingsViewModel: ViewModel, EventEmitter {
    private let session: Session
    private let preferences: Preferences
    private var observers = [AnyCancellable]()
    private let eventSubject = PassthroughSubject<SettingsEvent, Never>()
    private var sectionsSubject = CurrentValueSubject<[SettingsSection], Never>([])
    let state: SettingsViewState

    var events: AnyPublisher<SettingsEvent, Never> {
        return eventSubject.eraseToAnyPublisher()
    }

    init(session: Session, preferences: Preferences) {
        self.session = session
        self.preferences = preferences
        state = SettingsViewState(sections: sectionsSubject.eraseToAnyPublisher())

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

    func handle(_ event: SettingsViewEvent) {
        switch event {
        case .doneSelected:
            eventSubject.send(.complete)
        case let .changeServerSelected(source):
            handleChangeServerSelected(from: source)
        case let .serverSelected(index):
            let server = preferences.getServers()[index]
            eventSubject.send(.edit(server: server))
        case .addServerSelected:
            eventSubject.send(.addServer)
        case .advancedSettingsSelected:
            eventSubject.send(.advancedSettings)
        }
    }

    private func handleChangeServerSelected(from source: PopoverSource) {
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

    private func updateSections() {
        let servers = preferences.getServers()
        var sections = [SettingsSection]()

        if servers.count > 1, let server = session.server {
            sections.append(SettingsSection(type: .changeServer, items: [.changeServer(server.name)]))
        }

        let serverItems = servers.map { SettingsItem.server(id: $0.id, name: $0.name) }
        sections.append(SettingsSection(type: .servers, items: serverItems + [.addServer]))
        sections.append(SettingsSection(type: .advancedSettings, items: [.advancedSettings]))
        sectionsSubject.send(sections)
    }
}
