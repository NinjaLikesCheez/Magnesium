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

final class AppCoordinator: Coordinator {
    private let window: UIWindow
    private lazy var session: Session = DefaultSession(preferences: preferences)
    let events: AnyPublisher<Never, Never> = Empty().eraseToAnyPublisher()
    var observers = [AnyCancellable]()
    var childCoordinators = [AnyHashable: AnyCoordinator]()

    private var preferences: Preferences = {
        let preferences = UserDefaultsPreferences()
        _ = try? preferences.registerDefault(2, for: PreferenceKeys.autoRefreshInterval)
        return preferences
    }()

    private lazy var splitViewController: PresentableSplitViewController = {
        let splitViewController = PresentableSplitViewController()
        splitViewController.delegate = self
        splitViewController.preferredDisplayMode = .allVisible
        return splitViewController
    }()

    var presentable: Presentable {
        return splitViewController
    }

    init(window: UIWindow) {
        self.window = window
        window.rootViewController = presentable.viewController

        session.serverPublisher
            .sink { [weak self] in self?.show(server: $0) }
            .store(in: &observers)

        window.makeKeyAndVisible()
    }

    private func show(server: Server?) {
        let listCoordinator = DefaultTorrentListCoordinator(server: server, session: session, preferences: preferences)
        addChildCoordinator(listCoordinator) { [weak self] _, event in
            switch event {
            case .settings:
                self?.showSettings()
            case let .detail(viewModel: viewModel):
                self?.showTorrentDetail(viewModel: viewModel)
            }
        }
        let detailViewController = UIViewController()
        detailViewController.view.backgroundColor = .systemGroupedBackground
        let detailNavigationController = UINavigationController(rootViewController: detailViewController)
        splitViewController.viewControllers = [listCoordinator.presentable.viewController, detailNavigationController]
    }

    private func showSettings() {
        let coordinator = DefaultSettingsCoordinator(session: session, preferences: preferences)
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

    private func showTorrentDetail(viewModel: TorrentDetailViewModel) {
        let coordinator = DefaultTorrentDetailCoordinator(viewModel: viewModel)
        addChildCoordinator(coordinator) { [weak self] coordinator, event in
            switch event {
            case .complete:
                self?.dismissDetailViewController(coordinator.presentable.viewController)
            }
        }
        splitViewController.showDetailViewController(coordinator.presentable.viewController, sender: nil)
    }

    private func dismissDetailViewController(_ viewController: UIViewController?) {
        guard let viewController = viewController else { return }
        if let navigationController = (viewController as? UINavigationController)?.navigationController {
            navigationController.popViewController(animated: true)
        } else {
            let viewController = UIViewController()
            viewController.view.backgroundColor = .systemGroupedBackground
            let navigationController = UINavigationController(rootViewController: viewController)
            splitViewController.showDetailViewController(navigationController, sender: nil)
        }
    }
}

extension AppCoordinator: UISplitViewControllerDelegate {
    func splitViewController(
        _ splitViewController: UISplitViewController,
        collapseSecondary secondaryViewController: UIViewController,
        onto primaryViewController: UIViewController
    ) -> Bool {
        if let navigationController = secondaryViewController as? UINavigationController,
            !(navigationController.viewControllers.first is TorrentDetailViewController) {
            return true
        }

        return false
    }
}
