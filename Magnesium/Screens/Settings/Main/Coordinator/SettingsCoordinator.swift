//
//  SettingsCoordinator.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-16.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import Coordinator
import Preferences
import UIKit

protocol SettingsCoordinator: Coordinator, AlertPresenter {
    var didComplete: AnyPublisher<Void, Never> { get }
    func showServerSettings(_ server: Server)
    func showAddServer()
    func complete()
}

final class DefaultSettingsCoordinator: SettingsCoordinator {
    private let session: Session
    private let preferences: Preferences
    private let didCompleteSubject = PassthroughSubject<Void, Never>()
    var observers = [AnyCancellable]()
    var childCoordinators = [Coordinator]()

    private lazy var navigationController: PresentableNavigationController = {
        let viewModel = DefaultSettingsViewModel(coordinator: self, session: session, preferences: preferences)
        let viewController = SettingsViewController(viewModel: viewModel)
        return PresentableNavigationController(rootViewController: viewController)
    }()

    var presentable: Presentable {
        return navigationController
    }

    var didComplete: AnyPublisher<Void, Never> {
        return didCompleteSubject.eraseToAnyPublisher()
    }

    init(session: Session, preferences: Preferences) {
        self.session = session
        self.preferences = preferences
    }

    func showServerSettings(_ server: Server) {
        let coordinator = DefaultServerSettingsCoordinator(server: server, preferences: preferences)
        addChildCoordinator(coordinator)
        coordinator.didComplete
            .sink { [weak self, weak coordinator] _ in
                self?.popToPreviousViewController(coordinator?.presentable.viewController)
            }
            .store(in: &observers)
        navigationController.pushViewController(coordinator.presentable.viewController, animated: true)
    }

    func showAddServer() {
        let coordinator = DefaultAddServerCoordinator(preferences: preferences)
        addChildCoordinator(coordinator)
        coordinator.didComplete
            .sink { [weak self, weak coordinator] _ in
                self?.popToPreviousViewController(coordinator?.presentable.viewController)
            }
            .store(in: &observers)
        navigationController.pushViewController(coordinator.presentable.viewController, animated: true)
    }

    func complete() {
        didCompleteSubject.send(())
        didCompleteSubject.send(completion: .finished)
    }

    private func popToPreviousViewController(_ viewController: UIViewController?) {
        guard let viewController = viewController,
            let index = navigationController.viewControllers.firstIndex(of: viewController), index > 0
        else {
            return
        }

        navigationController.popToViewController(navigationController.viewControllers[index - 1], animated: true)
    }
}
