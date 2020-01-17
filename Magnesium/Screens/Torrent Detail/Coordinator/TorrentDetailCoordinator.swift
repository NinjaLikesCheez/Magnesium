//
//  TorrentDetailCoordinator.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-16.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import UIKit

protocol TorrentDetailCoordinator: PresentationCoordinator {}

final class DefaultTorrentDetailCoordinator: TorrentDetailCoordinator {
    private let viewModel: TorrentDetailViewModel
    private let splitViewController: UISplitViewController
    private var navigationController: UINavigationController?
    var childCoordinators: [Coordinator] = []
    var childCoordinatorObservers: [AnyCancellable] = []

    var presentationViewController: UIViewController {
        return navigationController ?? splitViewController
    }

    init(viewModel: TorrentDetailViewModel, splitViewController: UISplitViewController) {
        self.viewModel = viewModel
        self.splitViewController = splitViewController
    }

    func start() -> Presentable {
        let viewController = TorrentDetailViewController(viewModel: viewModel)
        let navigationController = PresentableNavigationController(rootViewController: viewController)
        self.navigationController = navigationController
        splitViewController.showDetailViewController(navigationController, sender: nil)
        return navigationController
    }

    func complete() {
        if let navigationController = navigationController?.navigationController {
            navigationController.popViewController(animated: true)
        } else {
            let viewController = UIViewController()
            viewController.view.backgroundColor = .systemGroupedBackground
            let navigationController = UINavigationController(rootViewController: viewController)
            splitViewController.showDetailViewController(navigationController, sender: nil)
        }
    }
}
