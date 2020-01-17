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
    private let didCompleteSubject = PassthroughSubject<Never, Never>()
    var childCoordinators: [Coordinator] = []
    var childCoordinatorObservers: [AnyCancellable] = []

    var didComplete: AnyPublisher<Never, Never> {
        return didCompleteSubject.eraseToAnyPublisher()
    }

    var presentationViewController: UIViewController {
        return navigationController
    }

    init(navigationController: UINavigationController, session: Session, preferences: Preferences) {
        self.navigationController = navigationController
        self.session = session
        self.preferences = preferences
    }

    func start() {
        let viewModel = DefaultSettingsViewModel(coordinator: self, session: session, preferences: preferences)
        let viewController = SettingsViewController(viewModel: viewModel)
        navigationController.setViewControllers([viewController], animated: true)
    }

    func complete() {
        navigationController.dismiss(animated: true, completion: nil)
        didCompleteSubject.send(completion: .finished)
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
        coordinator.start()
    }

    func showAddServer() {
        guard let presenter = navigationController.topViewController else { return }
        let coordinator = DefaultAddServerCoordinator(
            navigationController: navigationController,
            presenter: presenter,
            preferences: preferences
        )
        addChildCoordinator(childCoordinator: coordinator)
        coordinator.start()
    }
}
