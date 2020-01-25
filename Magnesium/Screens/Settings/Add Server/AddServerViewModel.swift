//
//  AddServerViewModel.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-15.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import Coordinator

enum AddServerEvent {
    case selected(type: ServerType)
}

protocol AddServerViewModel {
    var events: AnyPublisher<AddServerEvent, Never> { get }
    var types: [String] { get }
    func didSelectType(at index: Int)
}

final class DefaultAddServerViewModel: AddServerViewModel {
    private let eventSubject = PassthroughSubject<AddServerEvent, Never>()
    private let serverTypes: [ServerType] = [.deluge, .transmission]

    var events: AnyPublisher<AddServerEvent, Never> {
        return eventSubject.eraseToAnyPublisher()
    }

    var types: [String] {
        return serverTypes.map { $0.displayString }
    }

    func didSelectType(at index: Int) {
        eventSubject.send(.selected(type: serverTypes[index]))
    }
}
