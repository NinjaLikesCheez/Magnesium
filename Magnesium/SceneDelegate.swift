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
        let credentialsURL = Bundle(for: type(of: self)).url(forResource: "deluge-credentials", withExtension: nil)!
        // swiftlint:disable:next force_try
        let credentials = try! JSONSerialization.jsonObject(with: Data(contentsOf: credentialsURL), options: [])
            as! [String: String] // swiftlint:disable:this force_cast
        let client = DelugeClient(
            baseURL: URL(string: credentials["url"]!)!,
            password: credentials["password"]!
        )

        let splitViewController = SplitViewController()
        splitViewController.viewControllers = [
            NavigationControllerScreen { navigator in
//                Screens.Torrents.list(viewModel: MockTorrentListViewModel(navigator: navigator))
                Screens.Torrents.list(viewModel: DelugeTorrentListViewModel(client: client, navigator: navigator))
            }.viewController()!,
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
