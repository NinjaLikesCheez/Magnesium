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

protocol TorrentListCoordinator: Coordinator, AlertPresenter {
    func showTorrentDetail(_ viewModel: TorrentDetailViewModel)
    func showSettings()
    func showAddLink() -> AnyPublisher<String, Never>
}

final class DefaultTorrentListCoordinator: TorrentListCoordinator {
    private let server: Server?
    private let presentationCoordinator: Coordinator
    private let session: Session
    private let preferences: Preferences
    var observers = [AnyCancellable]()
    var childCoordinators = [Coordinator]()

    private lazy var navigationController: PresentableNavigationController = {
        let viewModel = server?.listViewModel(coordinator: self, preferences: preferences)
            ?? EmptyTorrentListViewModel(coordinator: self)
        let viewController = TorrentListViewController(viewModel: viewModel)
        let navigationController = PresentableNavigationController(rootViewController: viewController)
        navigationController.navigationBar.prefersLargeTitles = true
        return navigationController
    }()

    var presentable: Presentable {
        return navigationController
    }

    init(server: Server?, presentationCoordinator: Coordinator, session: Session, preferences: Preferences) {
        self.server = server
        self.presentationCoordinator = presentationCoordinator
        self.session = session
        self.preferences = preferences
    }

    func showTorrentDetail(_ viewModel: TorrentDetailViewModel) {
        var viewModel = viewModel
        let coordinator = DefaultTorrentDetailCoordinator(viewModel: viewModel)
        viewModel.coordinator = coordinator
        addChildCoordinator(coordinator)
        coordinator.didComplete
            .sink { [weak self, weak coordinator] _ in
                self?.dismissDetailViewController(coordinator?.presentable.viewController)
            }
            .store(in: &observers)
        navigationController.showDetailViewController(coordinator.presentable.viewController, sender: nil)
    }

    func showSettings() {
        let coordinator = DefaultSettingsCoordinator(session: session, preferences: preferences)
        presentationCoordinator.addChildCoordinator(coordinator)
        coordinator.didComplete
            .sink { [weak presentationCoordinator] _ in
                presentationCoordinator?.presentable.viewController.dismiss(animated: true)
            }
            .store(in: &presentationCoordinator.observers)
        let viewController = coordinator.presentable.viewController
        viewController.modalPresentationStyle = .formSheet
        presentationCoordinator.presentable.viewController.present(viewController, animated: true, completion: nil)
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
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            subject.send(completion: .finished)
        })
        presentable.viewController.present(alertController, animated: true, completion: nil)
        return subject.eraseToAnyPublisher()
    }

    private func dismissDetailViewController(_ viewController: UIViewController?) {
        guard let viewController = viewController else { return }
        if let navigationController = (viewController as? UINavigationController)?.navigationController {
            navigationController.popViewController(animated: true)
        } else {
            let viewController = UIViewController()
            viewController.view.backgroundColor = .systemGroupedBackground
            let navigationController = UINavigationController(rootViewController: viewController)
            self.navigationController.showDetailViewController(navigationController, sender: nil)
        }
    }
}
