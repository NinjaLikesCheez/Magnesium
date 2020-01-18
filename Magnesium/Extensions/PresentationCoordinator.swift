//
//  PresentationCoordinator.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-16.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Coordinator
import UIKit

protocol PresentationCoordinator: Coordinator {
    var presentationViewController: UIViewController { get }
}

extension PresentationCoordinator {
    func showAlert(_ alert: Alert, from source: PopoverSource? = nil) {
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
        presentationViewController.present(alertController, animated: true, completion: nil)
    }
}
