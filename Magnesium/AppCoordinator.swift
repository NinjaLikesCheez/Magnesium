//
//  AppCoordinator.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-16.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import Preferences
import UIKit

final class AppCoordinator: Coordinator {
    private let window: UIWindow
    private lazy var session: Session = DefaultSession(preferences: preferences)

    private var preferences: Preferences = {
        let preferences = UserDefaultsPreferences()
        _ = try? preferences.registerDefault(2, for: PreferenceKeys.autoRefreshInterval)
        return preferences
    }()

    let didComplete: AnyPublisher<Never, Never> = Empty().eraseToAnyPublisher()
    var childCoordinators: [Coordinator] = []
    var childCoordinatorObservers: [AnyCancellable] = []

    init(window: UIWindow) {
        self.window = window
    }

    func start() {
        let splitViewController = SplitViewController()
        window.rootViewController = splitViewController
        let coordinator = DefaultTorrentListCoordinator(
            splitViewController: splitViewController,
            session: session,
            preferences: preferences
        )
        addChildCoordinator(childCoordinator: coordinator)
        coordinator.start()
        window.makeKeyAndVisible()
    }
}
