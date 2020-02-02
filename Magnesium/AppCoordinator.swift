//
//  AppCoordinator.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-16.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import Coordinator
import Preferences
import UIKit

final class AppCoordinator: Coordinator, AlertPresenter {
    private let window: UIWindow
    private let preferences = UserDefaultsPreferences()
    private lazy var session: Session = DefaultSession(preferences: preferences)
    private lazy var addFileFlow = AddFileFlow(viewController: splitViewController, session: session)
    let events: AnyPublisher<Never, Never> = Empty().eraseToAnyPublisher()
    let received: AnyPublisher<Never, Never> = Empty().eraseToAnyPublisher()
    var observers = [AnyCancellable]()
    var childCoordinators = [AnyHashable: AnyCoordinator]()

    private lazy var splitViewController: PresentableSplitViewController = {
        let splitViewController = PresentableSplitViewController()
        splitViewController.delegate = self
        splitViewController.preferredDisplayMode = .allVisible
        return splitViewController
    }()

    private var masterNavigationController: PresentableNavigationController = {
        let navigationController = PresentableNavigationController()
        navigationController.navigationBar.prefersLargeTitles = true
        return navigationController
    }()

    var presentable: Presentable {
        return splitViewController
    }

    init(window: UIWindow) {
        self.window = window
        session.serverPublisher
            .sink { [weak self] in self?.show(server: $0) }
            .store(in: &observers)
        window.rootViewController = splitViewController
        window.makeKeyAndVisible()
    }

    private func show(server: Server?) {
        let listCoordinator = TorrentListCoordinator(server: server, session: session, preferences: preferences)
        addChildCoordinator(listCoordinator) { [weak self] _, event in
            switch event {
            case .settings:
                self?.showSettings()
            case let .detail(viewModel: viewModel):
                self?.showTorrentDetail(viewModel: viewModel)
            }
        }
        masterNavigationController.setViewControllers([listCoordinator.presentable.viewController], animated: false)
        let detailViewController = UIViewController()
        detailViewController.view.backgroundColor = .systemGroupedBackground
        let detailNavigationController = UINavigationController(rootViewController: detailViewController)
        splitViewController.viewControllers = [masterNavigationController, detailNavigationController]
    }

    private func showSettings() {
        let coordinator = SettingsCoordinator(session: session, preferences: preferences)
        addChildCoordinator(coordinator) { coordinator, event in
            switch event {
            case .complete:
                coordinator.presentable.viewController.dismiss(animated: true)
            }
        }
        let viewController = coordinator.presentable.viewController
        viewController.modalPresentationStyle = .formSheet
        splitViewController.present(viewController, animated: true, completion: nil)
    }

    private func showTorrentDetail(viewModel: AnyTorrentDetailViewModel) {
        let coordinator = TorrentDetailCoordinator(viewModel: viewModel)
        addChildCoordinator(coordinator) { [weak self] coordinator, event in
            switch event {
            case .complete:
                self?.dismissDetailViewController(coordinator.presentable.viewController)
            }
        }
        splitViewController.showDetailViewController(coordinator.presentable.viewController, sender: nil)
    }

    private func dismissDetailViewController(_ viewController: UIViewController) {
        let detailViewController = UIViewController()
        detailViewController.view.backgroundColor = .systemGroupedBackground
        let detailNavigationController = UINavigationController(rootViewController: detailViewController)

        UIView.performWithoutAnimation {
            splitViewController.showDetailViewController(detailNavigationController, sender: nil)
        }

        if masterNavigationController.viewControllers.contains(detailNavigationController) {
            masterNavigationController.popViewController(animated: false)
        }

        let viewController = viewController is UINavigationController
            ? viewController
            : viewController.navigationController ?? viewController
        if let index = masterNavigationController.viewControllers.firstIndex(of: viewController), index > 0 {
            let previousViewController = masterNavigationController.viewControllers[index - 1]
            masterNavigationController.popToViewController(previousViewController, animated: true)
        }
    }

    func addTorrentFile(at url: URL) {
        guard let server = session.server else { return }
        var alert = Alert(
            title: "Add Torrent",
            message: "Add \(url.lastPathComponent) to \(server.name)?",
            style: .alert
        )
        alert.addAction(AlertAction(title: "Add", style: .default) {
            self.addFileFlow.addFile(at: url)
        })
        alert.addAction(AlertAction(title: "Cancel", style: .cancel))
        showAlert(alert, useTopViewController: true)
    }
}

extension AppCoordinator: UISplitViewControllerDelegate {
    func splitViewController(
        _ splitViewController: UISplitViewController,
        collapseSecondary secondaryViewController: UIViewController,
        onto primaryViewController: UIViewController
    ) -> Bool {
        if let navigationController = secondaryViewController as? UINavigationController,
            !(navigationController.viewControllers.first is TorrentDetailViewControllerIdentifiable) {
            return true
        }

        return false
    }
}
