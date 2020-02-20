//
//  SwipeAction.swift
//  Magnesium
//
//  Created by James Hurst on 2020-02-19.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import UIKit

/// A model describing an action to be displayed when a cell is swiped.
struct SwipeAction {
    /// The style of an action.
    enum Style {
        case normal
        case destructive
    }

    /// The title displayed on the action button.
    var title: String?
    /// The image to display in the action button.
    var image: UIImage?
    /// The background color of the action button.
    var backgroundColor: UIColor?
    /// The style applied to the action button.
    var style: Style = .normal
    /// The handler to run when the action button is selected.
    var handler: () -> Void
}
