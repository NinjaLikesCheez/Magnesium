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

protocol SettingsCoordinator: PresentationCoordinator {
    func showServerSettings(_ server: Server)
    func showAddServer()
}

final class DefaultSettingsCoordinator: SettingsCoordinator {
    private let navigationController: UINavigationController
    private let session: Session
    private let preferences: Preferences
    var childCoordinators: [Coordinator] = []
    var childCoordinatorObservers: [AnyCancellable] = []

    var presentationViewController: UIViewController {
        return navigationController
    }

    init(navigationController: UINavigationController, session: Session, preferences: Preferences) {
        self.navigationController = navigationController
        self.session = session
        self.preferences = preferences
    }

    func start() -> Presentable {
        let viewModel = DefaultSettingsViewModel(coordinator: self, session: session, preferences: preferences)
        let viewController = SettingsViewController(viewModel: viewModel)
        navigationController.setViewControllers([viewController], animated: true)
        return viewController
    }

    func complete() {
        navigationController.dismiss(animated: true, completion: nil)
    }

    func showServerSettings(_ server: Server) {
        guard let presenter = navigationController.topViewController else { return }
        let coordinator = DefaultServerSettingsCoordinator(
            server: server,
            navigationController: navigationController,
            presenter: presenter,
            preferences: preferences
        )
        addChildCoordinator(childCoordinator: coordinator)
        startChildCoordinator(childCoordinator: coordinator)
    }

    func showAddServer() {
        guard let presenter = navigationController.topViewController else { return }
        let coordinator = DefaultAddServerCoordinator(
            navigationController: navigationController,
            presenter: presenter,
            preferences: preferences
        )
        addChildCoordinator(childCoordinator: coordinator)
        startChildCoordinator(childCoordinator: coordinator)
    }
}
