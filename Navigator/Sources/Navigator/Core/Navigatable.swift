//
//  Navigatable.swift
//  Navigator
//
//  Created by James Hurst on 2019-12-19.
//  Copyright © 2019 James Hurst. All rights reserved.
//

import UIKit

/// A view controller that can be displayed.
public protocol Navigatable {
    /// Returns the view controller to be navigated to.
    func viewController() -> UIViewController?
}
