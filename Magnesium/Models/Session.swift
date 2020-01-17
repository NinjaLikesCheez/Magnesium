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
    var server: Server? { get set }
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

    var server: Server? {
        didSet {
            setupServerObserver()
            serverSubject.send(server)
            if let server = server {
                _ = try? preferences.set(server.id, for: PreferenceKeys.selectedServerID)
            } else {
                preferences.removeValue(for: PreferenceKeys.selectedServerID)
            }
        }
    }

    init(preferences: Preferences) {
        self.preferences = preferences
        server = preferences.getSelectedServer()
        setupServerObserver()
        serverSubject.send(server)
    }

    private func setupServerObserver() {
        guard let server = server else {
            serverObserver = preferences.valueUpdatedPublisher(for: PreferenceKeys.servers)
                .sink(receiveValue: { [weak self] servers in
                    self?.server = servers?.first
                })
            return
        }
        serverObserver = preferences.serverUpdatedPublisher(for: server)
            .sink { [weak self] server in
                if let server = server {
                    self?.server = server
                } else {
                    self?.server = self?.preferences.getSelectedServer()
                }
            }
    }
}
