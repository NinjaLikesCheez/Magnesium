//
//  AlertAction.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-16.
//  Copyright © 2020 James Hurst. All rights reserved.
//

/// A model describing an alert action.
struct AlertAction {
    /// The style of an action's button.
    enum Style {
        case `default`
        case cancel
        case destructive
    }

    /// The title displayed on the action's button.
    var title: String?
    /// The style applied to the action's button.
    var style: Style
    /// The handler to run when the action's button is selected.
    var handler: (() -> Void)?
}
