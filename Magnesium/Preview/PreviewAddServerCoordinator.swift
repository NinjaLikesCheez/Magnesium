//
//  PreviewAddServerCoordinator.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-16.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine

#if DEBUG
    final class PreviewAddServerCoordinator: PreviewCoordinator, AddServerCoordinator {
        let didComplete: AnyPublisher<Void, Never> = Empty().eraseToAnyPublisher()
        func showServerSettings(for type: ServerType) {}
        func complete() {}
    }
#endif
