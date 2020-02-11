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

    mutating func addAction(_ action: AlertAction) {
        actions.append(action)
    }
}
