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
    var didComplete: AnyPublisher<Never, Never> { get }
    func start()
    func complete()
}

extension Coordinator {
    func complete() {}

    func addChildCoordinator(childCoordinator: Coordinator) {
        childCoordinators.append(childCoordinator)
        childCoordinator.didComplete
            .sink(receiveCompletion: { [weak self] _ in
                self?.removeChildCoordinator(childCoordinator: childCoordinator)
            }, receiveValue: { _ in })
            .store(in: &childCoordinatorObservers)
    }

    func removeChildCoordinator(childCoordinator: Coordinator) {
        childCoordinators = childCoordinators.filter { $0 !== childCoordinator }
    }
}
