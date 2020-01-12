//
//  NavigationControllerScreen.swift
//  Magnesium
//
//  Created by James Hurst on 2019-12-19.
//  Copyright © 2019 James Hurst. All rights reserved.
//

import Navigator
import UIKit

struct NavigationControllerScreen: Navigatable {
    let root: Navigatable

    init(_ root: Navigatable) {
        self.root = root
    }

    func viewController() -> UIViewController? {
        guard let viewController = root.viewController() else { return nil }
        let navigationController = UINavigationController(rootViewController: viewController)
        navigationController.navigationBar.prefersLargeTitles = true
        return navigationController
    }
}
