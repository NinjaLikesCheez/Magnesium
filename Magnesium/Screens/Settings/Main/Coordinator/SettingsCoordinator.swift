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

enum SettingsCoordinatorEvent {
    case complete
}

final class SettingsCoordinator: Coordinator, AlertPresenter {
    private let preferences: Preferences
    private let navigationController: PresentableNavigationController
    private let eventSubject = PassthroughSubject<SettingsCoordinatorEvent, Never>()
    let received: AnyPublisher<SettingsEvent, Never>
    var observers = [AnyCancellable]()
    var childCoordinators = [AnyHashable: AnyCoordinator]()

    var presentable: Presentable {
        return navigationController
    }

    var events: AnyPublisher<SettingsCoordinatorEvent, Never> {
        return eventSubject.eraseToAnyPublisher()
    }

    init(session: Session, preferences: Preferences) {
        self.preferences = preferences
        let viewModel = SettingsViewModel(session: session, preferences: preferences)
        let viewController = SettingsViewController(viewModel: viewModel)
        navigationController = PresentableNavigationController(rootViewController: viewController)
        received = viewModel.events
    }

    func handle(_ event: SettingsEvent) {
        switch event {
        case .complete:
            eventSubject.send(.complete)
        case let .selected(server: server):
            showSettings(for: server)
        case .addServer:
            showAddServer()
        case let .alert(alert, source: source):
            showAlert(alert, from: source)
        }
    }

    private func showSettings(for server: Server) {
        let coordinator = ServerSettingsCoordinator(server: server, preferences: preferences)
        addChildCoordinator(coordinator) { [weak self] coordinator, event in
            switch event {
            case .complete:
                self?.popToPreviousViewController(coordinator.presentable.viewController)
            }
        }
        navigationController.pushViewController(coordinator.presentable.viewController, animated: true)
    }

    private func showAddServer() {
        let coordinator = DefaultAddServerCoordinator(preferences: preferences)
        addChildCoordinator(coordinator) { [weak self] coordinator, event in
            switch event {
            case .complete:
                self?.popToPreviousViewController(coordinator.presentable.viewController)
            }
        }
        navigationController.pushViewController(coordinator.presentable.viewController, animated: true)
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
