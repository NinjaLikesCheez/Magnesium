//
//  NavigationControllerScreen.swift
//  Magnesium
//
//  Created by James Hurst on 2019-12-19.
//  Copyright © 2019 James Hurst. All rights reserved.
//

import UIKit

final class NavigationControllerScreen: Navigatable {
    let builder: (Navigator) -> Navigatable?

    init(_ builder: @escaping ((Navigator) -> Navigatable?)) {
        self.builder = builder
    }

    func viewController() -> UIViewController? {
        let navigationController = UINavigationController()
        navigationController.navigationBar.prefersLargeTitles = true
        let navigator = DefaultNavigator(
            presentationContext: PresentationContext(viewController: navigationController)
        )
        guard let viewController = builder(navigator)?.viewController() else { return nil }
        navigationController.viewControllers = [viewController]
        return navigationController
    }
}
