//
//  SettingsCoordinator.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-16.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import Preferences
import UIKit

protocol SettingsCoordinator: Coordinator {
    func showServerSettings(_ server: Server)
    func showAddServer()
}

final class DefaultSettingsCoordinator: SettingsCoordinator {
    private let navigatonController: UINavigationController
    private let preferences: Preferences
    private let didCompleteSubject = PassthroughSubject<Never, Never>()
    var childCoordinators: [Coordinator] = []
    var childCoordinatorObservers: [AnyCancellable] = []

    var didComplete: AnyPublisher<Never, Never> {
        return didCompleteSubject.eraseToAnyPublisher()
    }

    init(navigatonController: UINavigationController, preferences: Preferences) {
        self.navigatonController = navigatonController
        self.preferences = preferences
    }

    func start() {
        let viewModel = DefaultSettingsViewModel(coordinator: self, preferences: preferences)
        let viewController = SettingsViewController(viewModel: viewModel)
        navigatonController.setViewControllers([viewController], animated: true)
    }

    func complete() {
        navigatonController.dismiss(animated: true, completion: nil)
        didCompleteSubject.send(completion: .finished)
    }

    func showServerSettings(_ server: Server) {
        guard let presenter = navigatonController.topViewController else { return }
        let coordinator = DefaultServerSettingsCoordinator(
            server: server,
            navigationController: navigatonController,
            presenter: presenter,
            preferences: preferences
        )
        addChildCoordinator(childCoordinator: coordinator)
        coordinator.start()
    }

    func showAddServer() {
        guard let presenter = navigatonController.topViewController else { return }
        let coordinator = DefaultAddServerCoordinator(
            navigationController: navigatonController,
            presenter: presenter,
            preferences: preferences
        )
        addChildCoordinator(childCoordinator: coordinator)
        coordinator.start()
    }
}
