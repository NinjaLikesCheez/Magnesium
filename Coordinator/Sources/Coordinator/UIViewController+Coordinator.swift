//
//  UIViewController+Coordinator.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-17.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import UIKit

extension UIViewController {
    var shouldSendDismiss: Bool {
        return isBeingDismissed || isMovingFromParent || !isInViewHierarchy
    }

    var isInViewHierarchy: Bool {
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
