//
//  Alert+UIKit.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-16.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import UIKit

extension Alert {
    func createAlertController() -> UIAlertController {
        let alertController = UIAlertController(
            title: title,
            message: message,
            preferredStyle: style.alertControllerStyle
        )

        for action in actions {
            alertController.addAction(UIAlertAction(
                title: action.title,
                style: action.style.alertActionStyle,
                handler: { _ in action.handler?() }
            ))
        }

        return alertController
    }
}

private extension Alert.Style {
    var alertControllerStyle: UIAlertController.Style {
        switch self {
        case .actionSheet:
            return .actionSheet
        case .alert:
            return .alert
        }
    }
}

private extension AlertAction.Style {
    var alertActionStyle: UIAlertAction.Style {
        switch self {
        case .default:
            return .default
        case .cancel:
            return .cancel
        case .destructive:
            return .destructive
        }
    }
}
