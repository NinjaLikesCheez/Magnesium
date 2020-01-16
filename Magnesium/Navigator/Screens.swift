//
//  Screens.swift
//  Magnesium
//
//  Created by James Hurst on 2019-12-19.
//  Copyright © 2019 James Hurst. All rights reserved.
//

import Navigator
import UIKit

enum Screens: Navigatable {
    case torrentList(viewModel: TorrentListViewModel)
    case torrentDetail(viewModel: TorrentDetailViewModel)
    case torrentDetailEmpty
    case settings(viewModel: SettingsViewModel)
    case addServer(viewModel: AddServerViewModel)
    case delugeSettings(viewModel: DelugeSettingsViewModel)

    func viewController() -> UIViewController? {
        switch self {
        case let .torrentList(viewModel: viewModel):
            return TorrentListViewController(viewModel: viewModel)
        case let .torrentDetail(viewModel: viewModel):
            return TorrentDetailViewController(viewModel: viewModel)
        case .torrentDetailEmpty:
            let viewController = UIViewController()
            viewController.view.backgroundColor = .systemGroupedBackground
            return UINavigationController(rootViewController: viewController)
        case let .settings(viewModel):
            return SettingsViewController(viewModel: viewModel)
        case let .addServer(viewModel: viewModel):
            return AddServerViewController(viewModel: viewModel)
        case let .delugeSettings(viewModel: viewModel):
            return DelugeSettingsViewController(viewModel: viewModel)
        }
    }
}
