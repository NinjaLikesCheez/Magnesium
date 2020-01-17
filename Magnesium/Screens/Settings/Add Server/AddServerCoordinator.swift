//
//  AddServerCoordinator.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-16.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import Preferences
import UIKit

protocol AddServerCoordinator: ServerSettingsCoordinator {
    func showServerSettings(for type: ServerType)
}

final class DefaultAddServerCoordinator: AddServerCoordinator {
    private let navigationController: UINavigationController
    private let presenter: UIViewController
    private let preferences: Preferences
    var childCoordinators: [Coordinator] = []
    var childCoordinatorObservers: [AnyCancellable] = []

    var presentationViewController: UIViewController {
        return navigationController
    }

    init(navigationController: UINavigationController, presenter: UIViewController, preferences: Preferences) {
        self.navigationController = navigationController
        self.presenter = presenter
        self.preferences = preferences
    }

    func start() -> Presentable {
        let viewModel = DefaultAddServerViewModel(coordinator: self)
        let viewController = AddServerViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
        return viewController
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
