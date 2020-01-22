//
//  TorrentListCoordinator.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-16.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import Coordinator
import Preferences
import UIKit

protocol TorrentListCoordinator: PresentationCoordinator {
    func showTorrentDetail(_ viewModel: TorrentDetailViewModel)
    func showSettings()
    func showAddLink() -> AnyPublisher<String, Never>
}

final class DefaultTorrentListCoordinator: TorrentListCoordinator {
    private let splitViewController: UISplitViewController
    private let session: Session
    private let preferences: Preferences
    private var masterNavigationController: UINavigationController?
    private var observers = [AnyCancellable]()
    var childCoordinators: [Coordinator] = []
    var childCoordinatorObservers: [AnyCancellable] = []

    var presentationViewController: UIViewController {
        return masterNavigationController ?? splitViewController
    }

    init(splitViewController: UISplitViewController, session: Session, preferences: Preferences) {
        self.splitViewController = splitViewController
        self.session = session
        self.preferences = preferences
    }

    func start() -> Presentable {
        observers = []
        let masterNavigationController = PresentableNavigationController()
        masterNavigationController.navigationBar.prefersLargeTitles = true
        self.masterNavigationController = masterNavigationController
        session.serverPublisher
            .sink { [weak self] in self?.start(with: $0) }
            .store(in: &observers)
        return masterNavigationController
    }

    private func start(with server: Server?) {
        guard let masterNavigationController = masterNavigationController else { return }

        let viewModel = server?.listViewModel(coordinator: self, preferences: preferences)
            ?? EmptyTorrentListViewModel(coordinator: self)
        let viewController = TorrentListViewController(viewModel: viewModel)
        masterNavigationController.setViewControllers([viewController], animated: false)

        let detailViewController = UIViewController()
        detailViewController.view.backgroundColor = .systemGroupedBackground
        let detailNavigationController = UINavigationController(rootViewController: detailViewController)
        splitViewController.viewControllers = [masterNavigationController, detailNavigationController]
    }

    func showTorrentDetail(_ viewModel: TorrentDetailViewModel) {
        var viewModel = viewModel
        let coordinator = DefaultTorrentDetailCoordinator(
            viewModel: viewModel,
            splitViewController: splitViewController
        )
        viewModel.coordinator = coordinator
        addChildCoordinator(childCoordinator: coordinator)
        startChildCoordinator(childCoordinator: coordinator)
    }

    func showSettings() {
        let navigationController = UINavigationController()
        let coordinator = DefaultSettingsCoordinator(
            navigationController: navigationController,
            session: session,
            preferences: preferences
        )
        addChildCoordinator(childCoordinator: coordinator)
        startChildCoordinator(childCoordinator: coordinator)
        navigationController.modalPresentationStyle = .formSheet
        splitViewController.present(navigationController, animated: true, completion: nil)
    }

    func showAddLink() -> AnyPublisher<String, Never> {
        let subject = PassthroughSubject<String, Never>()
        let alertController = UIAlertController(
            title: "Enter a URL",
            message: "This can be either a link to a torrent or a magnet link.",
            preferredStyle: .alert
        )
        alertController.addTextField { textField in
            textField.textContentType = .URL
            textField.placeholder = "magnet:?xt=urn:btih:c12fe1c06bba254a9dc9f519b335aa7c1367a88a"
        }
        alertController.addAction(UIAlertAction(title: "Add", style: .default) { _ in
            subject.send(alertController.textFields?.first?.text ?? "")
            subject.send(completion: .finished)
        })
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        presentationViewController.present(alertController, animated: true, completion: nil)
        return subject.eraseToAnyPublisher()
    }
}
