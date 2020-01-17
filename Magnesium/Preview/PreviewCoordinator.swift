//
//  PreviewCoordinator.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-16.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import UIKit

#if DEBUG
    class PreviewCoordinator: Coordinator, PresentationCoordinator {
        let didComplete: AnyPublisher<Never, Never> = Empty().eraseToAnyPublisher()
        let presentationViewController = UIViewController()
        var childCoordinators: [Coordinator] = []
        var childCoordinatorObservers: [AnyCancellable] = []
        func start() {}
    }
#endif
