//
//  PresentationCoordinator.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-16.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import UIKit

protocol PresentationCoordinator: Coordinator {
    var presentationViewController: UIViewController { get }
}

extension PresentationCoordinator {
    func showAlert(_ alert: Alert) {
        presentationViewController.present(alert.createAlertController(), animated: true, completion: nil)
    }
}
