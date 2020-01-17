//
//  Coordinator.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-16.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine

protocol Coordinator: AnyObject {
    var childCoordinators: [Coordinator] { get set }
    var childCoordinatorObservers: [AnyCancellable] { get set }
    func start() -> Presentable
    func complete()
}

extension Coordinator {
    func complete() {}

    func addChildCoordinator(childCoordinator: Coordinator) {
        childCoordinators.append(childCoordinator)
    }

    func startChildCoordinator(childCoordinator: Coordinator) {
        childCoordinator.start()
            .didDismiss
            .sink(receiveCompletion: { [weak self, weak childCoordinator] _ in
                guard let childCoordinator = childCoordinator else { return }
                self?.removeChildCoordinator(childCoordinator: childCoordinator)
            }, receiveValue: { _ in })
            .store(in: &childCoordinatorObservers)
    }

    func removeChildCoordinator(childCoordinator: Coordinator) {
        childCoordinators = childCoordinators.filter { $0 !== childCoordinator }
    }
}
