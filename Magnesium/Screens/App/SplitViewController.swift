//
//  SplitViewController.swift
//  Magnesium
//
//  Created by James Hurst on 2019-12-26.
//  Copyright © 2019 James Hurst. All rights reserved.
//

import UIKit

final class SplitViewController: UISplitViewController, UISplitViewControllerDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        preferredDisplayMode = .allVisible
    }

    func splitViewController(
        _ splitViewController: UISplitViewController,
        collapseSecondary secondaryViewController: UIViewController,
        onto primaryViewController: UIViewController
    ) -> Bool {
        if let navigationController = secondaryViewController as? UINavigationController,
            !(navigationController.viewControllers.first is TorrentDetailViewController) {
            return true
        }

        return false
    }
}
