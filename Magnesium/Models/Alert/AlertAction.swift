//
//  AlertAction.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-16.
//  Copyright © 2020 James Hurst. All rights reserved.
//

/// A model describing an alert action.
struct AlertAction {
    /// The style of an alert action.
    enum Style {
        case `default`
        case cancel
        case destructive
    }

    /// The action's title.
    var title: String?
    /// The action's style.
    var style: Style
    /// The handler to run when the action is triggered.
    var handler: (() -> Void)?
}
