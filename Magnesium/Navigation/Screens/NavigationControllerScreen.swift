//
//  NavigationControllerScreen.swift
//  Magnesium
//
//  Created by James Hurst on 2019-12-19.
//  Copyright © 2019 James Hurst. All rights reserved.
//

import UIKit

final class NavigationControllerScreen: Navigatable, NavigatorConfigurable {
    let root: Navigatable

    var navigator: Navigator? {
        get {
            return (root as? NavigatorConfigurable)?.navigator
        }
        set {
            var rootNavigatorConfigurable = root as? NavigatorConfigurable
            rootNavigatorConfigurable?.navigator = newValue
        }
    }

    init(_ root: Navigatable) {
        self.root = root
    }

    func viewController() -> UIViewController? {
        guard let viewController = root.viewController() else { return nil }
        guard !(viewController is UINavigationController) else { return viewController }
        return UINavigationController(rootViewController: viewController)
    }
}
