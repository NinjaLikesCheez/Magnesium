//
//  PreviewCoordinator.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-16.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import Coordinator
import UIKit

#if DEBUG
    class PreviewCoordinator: Coordinator {
        let presentable: Presentable = PresentableViewController()
        var observers = [AnyCancellable]()
        var childCoordinators = [Coordinator]()
    }
#endif
