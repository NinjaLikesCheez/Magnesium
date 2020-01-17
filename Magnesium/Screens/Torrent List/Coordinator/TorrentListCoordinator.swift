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
    private let didCompleteSubject = PassthroughSubject<Never, Never>()
    private var masterNavigationController: UINavigationController?
    private var observers = [AnyCancellable]()
    var childCoordinators = [Coordinator]()
    var childCoordinatorObservers = [AnyCancellable]()

    var didComplete: AnyPublisher<Never, Never> {
        return didCompleteSubject.eraseToAnyPublisher()
    }

    init(splitViewController: UISplitViewController, preferences: Preferences) {
        self.splitViewController = splitViewController
        self.preferences = preferences
    }

    func start() {
        observers = []
        preferences.selectedServerPublisher
            .sink { [weak self] in self?.start(with: $0) }
            .store(in: &observers)
    }

    private func start(with server: Server?) {
        let viewModel = server?.listViewModel(coordinator: self, preferences: preferences)
            ?? EmptyTorrentListViewModel(coordinator: self, preferences: preferences)
        let viewController = TorrentListViewController(viewModel: viewModel)

        let navigationController = UINavigationController()
        navigationController.navigationBar.prefersLargeTitles = true
        navigationController.setViewControllers([viewController], animated: true)

        let detailViewController = UIViewController()
        detailViewController.view.backgroundColor = .systemGroupedBackground
        let detailNavigationController = UINavigationController(rootViewController: detailViewController)

        splitViewController.viewControllers = [navigationController, detailNavigationController]
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
}
