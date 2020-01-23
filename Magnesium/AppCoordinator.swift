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
    private class AppPresentable: Presentable {
        let didDismiss: AnyPublisher<Void, Never> = Just(()).eraseToAnyPublisher()
    }

    private let window: UIWindow
    private lazy var session: Session = DefaultSession(preferences: preferences)

    private var preferences: Preferences = {
        let preferences = UserDefaultsPreferences()
        _ = try? preferences.registerDefault(2, for: PreferenceKeys.autoRefreshInterval)
        return preferences
    }()

    var childCoordinators: [Coordinator] = []
    var childCoordinatorObservers: [AnyCancellable] = []

    init(window: UIWindow) {
        self.window = window
    }

    func start() -> Presentable {
        let splitViewController = SplitViewController()
        window.rootViewController = splitViewController
        let coordinator = DefaultTorrentListCoordinator(
            splitViewController: splitViewController,
            session: session,
            preferences: preferences
        )
        addChildCoordinator(childCoordinator: coordinator)
        startChildCoordinator(childCoordinator: coordinator)
        window.makeKeyAndVisible()
        return AppPresentable()
    }
}
