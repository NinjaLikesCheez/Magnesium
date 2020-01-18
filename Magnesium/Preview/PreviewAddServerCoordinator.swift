//
//  PreviewAddServerCoordinator.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-16.
//  Copyright © 2020 James Hurst. All rights reserved.
//

#if DEBUG
    final class PreviewAddServerCoordinator: PreviewCoordinator, AddServerCoordinator {
        func showServerSettings(for type: ServerType) {}
    }
#endif
