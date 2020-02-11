//
//  Alert.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-16.
//  Copyright © 2020 James Hurst. All rights reserved.
//

/// A model describing an alert.
struct Alert {
    /// The style of an alert.
    enum Style {
        case actionSheet
        case alert
    }

    /// The alert's title.
    var title: String?
    /// The alert's message.
    var message: String?
    /// The alert's style.
    var style: Style
    /// The alert's actions.
    var actions = [AlertAction]()

    /// Creates a new alert with the given properties.
    /// - Parameters:
    ///   - title: The alert's title.
    ///   - message: The alert's message.
    ///   - style: The alert's style.
    ///   - actions: The alert's actions.
    init(title: String?, message: String?, style: Style, actions: [AlertAction] = []) {
        self.title = title
        self.message = message
        self.style = style
        self.actions = actions
    }

    mutating func addAction(_ action: AlertAction) {
        actions.append(action)
    }
}
