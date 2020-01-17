//
//  SceneDelegate.swift
//  Magnesium
//
//  Created by James Hurst on 2019-11-11.
//  Copyright © 2019 James Hurst. All rights reserved.
//

import Preferences
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    private var coordinator: AppCoordinator!
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        let isRunningTests = NSClassFromString("XCTestCase") != nil
        guard !isRunningTests else {
            if let windowScene = scene as? UIWindowScene {
                let window = UIWindow(windowScene: windowScene)
                window.rootViewController = UIViewController()
                self.window = window
                window.makeKeyAndVisible()
            }
            return
        }

        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            self.window = window
            coordinator = AppCoordinator(window: window)
            coordinator.start()
        }
    }
}
