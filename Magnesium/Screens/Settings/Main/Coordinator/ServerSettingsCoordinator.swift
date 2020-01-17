//
//  EditServerCoordinator.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-16.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import Preferences
import UIKit

protocol ServerSettingsCoordinator: PresentationCoordinator {}

final class DefaultServerSettingsCoordinator: ServerSettingsCoordinator {
    private let server: Server
    private let navigationController: UINavigationController
    private let presenter: UIViewController
    private let preferences: Preferences
    var childCoordinators: [Coordinator] = []
    var childCoordinatorObservers: [AnyCancellable] = []

    var presentationViewController: UIViewController {
        return navigationController
    }

    init(
        server: Server,
        navigationController: UINavigationController,
        presenter: UIViewController,
        preferences: Preferences
    ) {
        self.server = server
        self.navigationController = navigationController
        self.presenter = presenter
        self.preferences = preferences
    }

    func start() -> Presentable {
        switch server.type {
        case .deluge:
            let viewModel = DefaultDelugeSettingsViewModel(
                coordinator: self,
                preferences: preferences,
                server: server
            )
            let viewController = DelugeSettingsViewController(viewModel: viewModel)
            navigationController.pushViewController(viewController, animated: true)
            return viewController
        }
    }

    func complete() {
        navigationController.popToViewController(presenter, animated: true)
    }

    func showServerSettings(for type: ServerType) {
        switch type {
        case .deluge:
            let viewModel = DefaultDelugeSettingsViewModel(coordinator: self, preferences: preferences)
            let viewController = DelugeSettingsViewController(viewModel: viewModel)
            navigationController.pushViewController(viewController, animated: true)
        }
    }
}
