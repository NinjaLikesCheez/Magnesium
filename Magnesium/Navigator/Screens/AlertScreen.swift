//
//  AlertScreen.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-08.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import UIKit

struct AlertScreen: Navigatable {
    private let model: AlertModel

    init(_ model: AlertModel) {
        self.model = model
    }

    func viewController() -> UIViewController? {
        let alertController = UIAlertController(
            title: model.title,
            message: model.message,
            preferredStyle: model.style.alertControllerStyle
        )

        for action in model.actions {
            alertController.addAction(UIAlertAction(
                title: action.title,
                style: action.style.alertActionStyle,
                handler: { _ in action.handler?() }
            ))
        }

        return alertController
    }
}

private extension AlertModel.Style {
    var alertControllerStyle: UIAlertController.Style {
        switch self {
        case .actionSheet:
            return .actionSheet
        case .alert:
            return .alert
        }
    }
}

private extension AlertActionModel.Style {
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
