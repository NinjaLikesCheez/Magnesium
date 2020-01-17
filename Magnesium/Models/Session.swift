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
    func updateServerWithDefault()
}

final class DefaultSession: Session {
    private let preferences: Preferences
    private let serverSubject = CurrentValueSubject<Server?, Never>(nil)

    var serverPublisher: AnyPublisher<Server?, Never> {
        return serverSubject.eraseToAnyPublisher()
    }

    var server: Server? {
        didSet {
            guard let server = server else { return }
            serverSubject.send(server)
            _ = try? preferences.set(server.id, for: PreferenceKeys.selectedServerID)
        }
    }

    init(preferences: Preferences) {
        self.preferences = preferences
        server = preferences.getSelectedServer()
        serverSubject.send(server)
    }

    func updateServerWithDefault() {
        server = preferences.getSelectedServer()
    }
}
