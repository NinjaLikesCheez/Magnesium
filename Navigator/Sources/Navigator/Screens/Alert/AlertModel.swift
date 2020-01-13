//
//  AlertModel.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-08.
//  Copyright © 2020 James Hurst. All rights reserved.
//

/// A model describing an alert.
public struct AlertModel {
    /// The style of an alert.
    public enum Style {
        case actionSheet
        case alert
    }

    /// The alert's title.
    public var title: String?
    /// The alert's message.
    public var message: String?
    /// The alert's style.
    public var style: Style
    /// The alert's actions.
    public var actions = [AlertActionModel]()
    /// The source to display the alert from in a popover presentation.
    public var popoverSource: PopoverSource?

    /// Creates a new alert with the given properties.
    /// - Parameters:
    ///   - title: The alert's title.
    ///   - message: The alert's message.
    ///   - style: The alert's style.
    public init(title: String?, message: String?, style: Style) {
        self.title = title
        self.message = message
        self.style = style
    }
}
