//
//  UIViewController+Coordinator.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-17.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import UIKit

extension UIViewController {
    var isBeingDismissedForCoordinator: Bool {
        var navigationControllerIsDismissing: Bool = false
        if let navigationController = navigationController {
            navigationControllerIsDismissing = navigationController.isBeingDismissed
                || navigationController.isMovingFromParent
        }
        return isBeingDismissed || isMovingFromParent || navigationControllerIsDismissing || !isInViewHierarchy
    }

    private var isInViewHierarchy: Bool {
        return isBeingPresented
            || presentingViewController != nil
            || presentedViewController != nil
            || parent != nil
            || view.window != nil
            || navigationController != nil
            || tabBarController != nil
            || splitViewController != nil
    }
}
