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
        let splitViewController = SplitViewController()
        let masterNavigationController = UINavigationController()
        masterNavigationController.navigationBar.prefersLargeTitles = true
        let viewModel = MockTorrentListViewModel(
            navigator: DefaultNavigator(
                presentationContext: PresentationContext(viewController: masterNavigationController)
            )
        )
        let torrentListViewController = TorrentListViewController(viewModel: viewModel)
        masterNavigationController.viewControllers = [torrentListViewController]
        let detailViewController = UIViewController()
        detailViewController.view.backgroundColor = .systemBackground
        splitViewController.viewControllers = [
            masterNavigationController,
            UINavigationController(rootViewController: detailViewController),
        ]

        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = splitViewController
            self.window = window
            window.makeKeyAndVisible()
        }
    }
}
