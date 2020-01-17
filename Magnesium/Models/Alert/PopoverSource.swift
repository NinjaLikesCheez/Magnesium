//
//  PopoverSource.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-16.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import UIKit

/// The source of a popover presentation.
public enum PopoverSource {
    /// The view and frame to present the popover from.
    case view(UIView, rect: CGRect)
    /// The bar button item to present the popover from.
    case barButton(UIBarButtonItem)
}
