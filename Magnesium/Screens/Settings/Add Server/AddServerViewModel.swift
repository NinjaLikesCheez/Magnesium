//
//  AddServerViewModel.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-15.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import ViewModel

enum AddServerEvent {
    case add(type: ServerType)
}

enum AddServerViewEvent {
    case selectType(index: Int)
}

struct AddServerViewState {
    var types: [String]
}

final class AddServerViewModel: ViewModel, EventEmitter {
    private let eventSubject = PassthroughSubject<AddServerEvent, Never>()
    private let serverTypes: [ServerType] = [.deluge, .transmission]
    let state: AddServerViewState

    init() {
        state = AddServerViewState(types: serverTypes.map { $0.localizedString })
    }

    var events: AnyPublisher<AddServerEvent, Never> {
        return eventSubject.eraseToAnyPublisher()
    }

    func handle(_ event: AddServerViewEvent) {
        switch event {
        case let .selectType(index: index):
            eventSubject.send(.add(type: serverTypes[index]))
        }
    }
}
