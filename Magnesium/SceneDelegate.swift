//
//  SceneDelegate.swift
//  Magnesium
//
//  Created by James Hurst on 2019-11-11.
//  Copyright © 2019 James Hurst. All rights reserved.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        let preferences = DefaultPreferenceManager()
        _ = try? preferences.registerDefault(1, for: PreferenceKeys.autoRefreshInterval)

        let credentialsURL = Bundle(for: type(of: self)).url(forResource: "deluge-credentials", withExtension: nil)!
        // swiftlint:disable:next force_try
        let credentials = try! JSONSerialization.jsonObject(with: Data(contentsOf: credentialsURL), options: [])
            as! [String: String] // swiftlint:disable:this force_cast
        let client = DefaultDelugeClient(
            baseURL: URL(string: credentials["url"]!)!,
            password: credentials["password"]!
        )

        let splitViewController = SplitViewController()
        let viewModel = DelugeTorrentListViewModel(client: client, preferences: preferences)
        let screen = NavigationControllerScreen(Screens.Torrents.list(viewModel: viewModel))
        let navigationController = screen.viewController()!
        viewModel.navigator = DefaultNavigator(viewController: navigationController)
        splitViewController.viewControllers = [
            navigationController,
            Screens.Torrents.emptyDetail.viewController()!,
        ]

        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = splitViewController
            self.window = window
            window.makeKeyAndVisible()
        }
    }
}
