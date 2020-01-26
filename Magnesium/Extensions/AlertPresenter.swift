//
//  AlertPresenter.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-16.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Coordinator
import UIKit

protocol AlertPresenter {
    func showAlert(_ alert: Alert, from source: PopoverSource?, useTopViewController: Bool)
}

extension AlertPresenter where Self: Coordinator {
    func showAlert(_ alert: Alert, from source: PopoverSource? = nil, useTopViewController: Bool = false) {
        let alertController = alert.createAlertController()
        switch source {
        case let .view(view, rect: rect):
            alertController.popoverPresentationController?.sourceView = view
            alertController.popoverPresentationController?.sourceRect = rect
        case let .barButton(barButtonItem):
            alertController.popoverPresentationController?.barButtonItem = barButtonItem
        case .none:
            break
        }

        if useTopViewController {
            var current = presentable.viewController
            while let next = current.presentedViewController {
                current = next
            }
            current.present(alertController, animated: true)
        } else {
            presentable.viewController.present(alertController, animated: true)
        }
    }
}
