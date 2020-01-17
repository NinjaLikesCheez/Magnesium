//
//  TorrentListCoordinator.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-16.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import Preferences
import UIKit

protocol TorrentListCoordinator: Coordinator {
    func showListForSelectedServer()
    func showTorrentDetail(_ viewModel: TorrentDetailViewModel)
    func showSettings()
}

final class DefaultTorrentListCoordinator: TorrentListCoordinator {
    private let splitViewController: UISplitViewController
    private let preferences: Preferences
    private var masterNavigationController: UINavigationController?
    private let didCompleteSubject = PassthroughSubject<Never, Never>()
    var childCoordinators: [Coordinator] = []
    var childCoordinatorObservers: [AnyCancellable] = []

    var didComplete: AnyPublisher<Never, Never> {
        return didCompleteSubject.eraseToAnyPublisher()
    }

    init(splitViewController: UISplitViewController, preferences: Preferences) {
        self.splitViewController = splitViewController
        self.preferences = preferences
    }

    func start() {
        let viewController = TorrentListViewController(viewModel: torrentListViewModel())
        let navigationController = UINavigationController()
        navigationController.navigationBar.prefersLargeTitles = true
        navigationController.setViewControllers([viewController], animated: true)
        splitViewController.viewControllers = [navigationController, emptyDetailViewController()]
        masterNavigationController = navigationController
    }

    func showListForSelectedServer() {
        start()
    }

    func showTorrentDetail(_ viewModel: TorrentDetailViewModel) {
        var viewModel = viewModel
        let coordinator = DefaultTorrentDetailCoordinator(
            viewModel: viewModel,
            splitViewController: splitViewController
        )
        addChildCoordinator(childCoordinator: coordinator)
        viewModel.coordinator = coordinator
        coordinator.start()
    }

    func showSettings() {
        let navigationController = UINavigationController()
        let coordinator = DefaultSettingsCoordinator(
            navigatonController: navigationController,
            preferences: preferences
        )
        addChildCoordinator(childCoordinator: coordinator)
        coordinator.start()
        splitViewController.present(navigationController, animated: true, completion: nil)
    }

    private func emptyDetailViewController() -> UIViewController {
        let viewController = UIViewController()
        viewController.view.backgroundColor = .systemGroupedBackground
        return UINavigationController(rootViewController: viewController)
    }

    private func torrentListViewModel() -> TorrentListViewModel {
        return preferences.getServers()
            .compactMap { $0.listViewModel(coordinator: self, preferences: preferences) }
            .last
            ?? EmptyTorrentListViewModel(coordinator: self, preferences: preferences)
    }
}
