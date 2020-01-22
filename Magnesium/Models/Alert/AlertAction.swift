//
//  AlertAction.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-16.
//  Copyright © 2020 James Hurst. All rights reserved.
//

/// A model describing an alert action.
public struct AlertAction {
    /// The style of an alert action.
    public enum Style {
        case `default`
        case cancel
        case destructive
    }

    /// The action's title.
    public var title: String?
    /// The action's style.
    public var style: Style
    /// The handler to run when the action is triggered.
    public var handler: (() -> Void)?

    /// Creates a new action with the given properties.
    /// - Parameters:
    ///   - title: The action's title.
    ///   - style: The action's style.
    ///   - handler: The action's handler.
    public init(title: String, style: Style, handler: (() -> Void)? = nil) {
        self.title = title
        self.style = style
        self.handler = handler
    }
}
