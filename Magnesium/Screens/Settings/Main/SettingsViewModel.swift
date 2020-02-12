//
//  SettingsViewModel.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-14.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import Foundation
import Preferences
import ViewModel

enum SettingsEvent {
    case complete
    case alert(Alert, source: PopoverSource?)
    case edit(server: Server)
    case addServer
    case refreshInterval
}

enum SettingsViewEvent {
    case doneSelected
    case changeServerSelected(source: PopoverSource)
    case serverSelected(index: Int)
    case addServerSelected
    case refreshIntervalSelected
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

        preferences.valueUpdatedPublisher(for: PreferenceKeys.servers).map { _ in () }
            .merge(with: session.serverPublisher.map { _ in () })
            .merge(with: preferences.valueUpdatedPublisher(for: PreferenceKeys.autoRefreshInterval).map { _ in () })
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
        case .refreshIntervalSelected:
            eventSubject.send(.refreshInterval)
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
        alert.addAction(.cancel())
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

        let refreshInterval = preferences.value(for: PreferenceKeys.autoRefreshInterval)
        let refreshString: String
        if refreshInterval <= 0 {
            refreshString = NSLocalizedString("refresh_interval_never", comment: "Never")
        } else {
            let format = NSLocalizedString("refresh_interval_seconds", comment: "{number} seconds")
            let seconds = String(format: "%.0f seconds", refreshInterval)
            refreshString = String.localizedStringWithFormat(format, seconds)
        }
        sections.append(SettingsSection(type: .general, items: [.refreshInterval(current: refreshString)]))

        sectionsSubject.send(sections)
    }
}
