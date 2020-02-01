//
//  Session.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-17.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import Preferences

protocol Session: AnyObject {
    var serverPublisher: AnyPublisher<Server?, Never> { get }
    var server: Server? { get }
    func setServer(_ server: Server)
}

final class DefaultSession: Session {
    private let preferences: Preferences
    private let serverSubject = CurrentValueSubject<Server?, Never>(nil)
    private var serverObserver: AnyCancellable?

    var serverPublisher: AnyPublisher<Server?, Never> {
        return serverSubject
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    private(set) var server: Server?
    init(preferences: Preferences) {
        self.preferences = preferences
        _setServer(preferences.getSelectedServer())
    }

    func setServer(_ server: Server) {
        _setServer(server)
    }

    private func _setServer(_ server: Server?) {
        self.server = server
        setupServerObserver()
        serverSubject.send(server)
        if let server = server {
            preferences.set(server.id, for: PreferenceKeys.selectedServerID)
        }
    }

    private func setupServerObserver() {
        guard let server = server else {
            serverObserver = preferences.valueUpdatedPublisher(for: PreferenceKeys.servers)
                .sink(receiveValue: { [weak self] servers in
                    self?._setServer(servers.first)
                })
            return
        }
        serverObserver = preferences.serverUpdatedPublisher(for: server)
            .sink { [weak self] server in
                if let server = server {
                    self?._setServer(server)
                } else {
                    self?._setServer(self?.preferences.getSelectedServer())
                }
            }
    }
}
