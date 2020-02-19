//
//  ServerErrorViewModel.swift
//  Magnesium
//
//  Created by James Hurst on 2020-02-18.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import Foundation
import ViewModel

enum ServerErrorEvent {
    case showSettings
    case editServer
}

enum ServerErrorViewEvent {
    case settingsSelected
    case editServerSelected
}

final class ServerErrorViewModel: ViewModel, EventEmitter {
    private let eventSubject = PassthroughSubject<ServerErrorEvent, Never>()
    let state: Void = ()

    var events: AnyPublisher<ServerErrorEvent, Never> {
        return eventSubject.eraseToAnyPublisher()
    }

    func handle(_ event: ServerErrorViewEvent) {
        switch event {
        case .settingsSelected:
            eventSubject.send(.showSettings)
        case .editServerSelected:
            eventSubject.send(.editServer)
        }
    }
}
