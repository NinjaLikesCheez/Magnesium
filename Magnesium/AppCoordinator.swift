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
    var observers = [AnyCancellable]()
    var childCoordinators = [Coordinator]()

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
        let listCoordinator = DefaultTorrentListCoordinator(
            server: server,
            presentationCoordinator: self,
            session: session,
            preferences: preferences
        )
        addChildCoordinator(listCoordinator)
        let detailViewController = UIViewController()
        detailViewController.view.backgroundColor = .systemGroupedBackground
        let detailNavigationController = UINavigationController(rootViewController: detailViewController)
        splitViewController.viewControllers = [listCoordinator.presentable.viewController, detailNavigationController]
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
