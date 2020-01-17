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
    func showDefaultServer()
    func showTorrentDetail(_ viewModel: TorrentDetailViewModel)
    func showSettings()
}

final class DefaultTorrentListCoordinator: TorrentListCoordinator {
    private let splitViewController: UISplitViewController
    private let session: Session
    private let preferences: Preferences
    private let didCompleteSubject = PassthroughSubject<Never, Never>()
    private var masterNavigationController: UINavigationController?
    private var detailCoordinator: Coordinator?
    private var observers = [AnyCancellable]()
    var childCoordinators = [Coordinator]()
    var childCoordinatorObservers = [AnyCancellable]()

    var didComplete: AnyPublisher<Never, Never> {
        return didCompleteSubject.eraseToAnyPublisher()
    }

    init(splitViewController: UISplitViewController, session: Session, preferences: Preferences) {
        self.splitViewController = splitViewController
        self.session = session
        self.preferences = preferences
    }

    func start() {
        observers = []
        masterNavigationController = UINavigationController()
        masterNavigationController?.navigationBar.prefersLargeTitles = true
        session.serverPublisher
            .sink { [weak self] in self?.start(with: $0) }
            .store(in: &observers)
    }

    private func start(with server: Server?) {
        guard let masterNavigationController = masterNavigationController else { return }
    
        let viewModel = server?.listViewModel(coordinator: self, preferences: preferences)
            ?? EmptyTorrentListViewModel(coordinator: self, preferences: preferences)
        let viewController = TorrentListViewController(viewModel: viewModel)
        masterNavigationController.setViewControllers([viewController], animated: true)

        let detailViewController = UIViewController()
        detailViewController.view.backgroundColor = .systemGroupedBackground
        let detailNavigationController = UINavigationController(rootViewController: detailViewController)
        splitViewController.viewControllers = [masterNavigationController, detailNavigationController]
    }

    func showDefaultServer() {
        session.updateServerWithDefault()
    }

    func showTorrentDetail(_ viewModel: TorrentDetailViewModel) {
        if let detailCoordinator = detailCoordinator {
            removeChildCoordinator(childCoordinator: detailCoordinator)
        }

        var viewModel = viewModel
        let coordinator = DefaultTorrentDetailCoordinator(
            viewModel: viewModel,
            splitViewController: splitViewController
        )
        detailCoordinator = coordinator
        addChildCoordinator(childCoordinator: coordinator)
        viewModel.coordinator = coordinator
        coordinator.start()
    }

    func showSettings() {
        let navigationController = UINavigationController()
        let coordinator = DefaultSettingsCoordinator(
            navigationController: navigationController,
            session: session,
            preferences: preferences
        )
        addChildCoordinator(childCoordinator: coordinator)
        coordinator.start()
        navigationController.modalPresentationStyle = .formSheet
        splitViewController.present(navigationController, animated: true, completion: nil)
    }
}
