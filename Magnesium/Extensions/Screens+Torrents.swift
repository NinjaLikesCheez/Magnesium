//
//  Screens+Torrents.swift
//  Magnesium
//
//  Created by James Hurst on 2019-12-19.
//  Copyright © 2019 James Hurst. All rights reserved.
//

import UIKit

extension Screens {
    enum Torrents: Navigatable {
        case list(viewModel: TorrentListViewModel)
        case detail(viewModel: TorrentDetailViewModel)
        case emptyDetail

        func viewController() -> UIViewController? {
            switch self {
            case let .list(viewModel: viewModel):
                return TorrentListViewController(viewModel: viewModel)
            case let .detail(viewModel: viewModel):
                return TorrentDetailViewController(viewModel: viewModel)
            case .emptyDetail:
                let viewController = UIViewController()
                viewController.view.backgroundColor = .systemGroupedBackground
                return UINavigationController(rootViewController: viewController)
            }
        }
    }
}
