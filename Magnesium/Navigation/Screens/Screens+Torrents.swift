//
//  Screens+Torrents.swift
//  Magnesium
//
//  Created by James Hurst on 2019-12-19.
//  Copyright © 2019 James Hurst. All rights reserved.
//

import UIKit

extension Screens {
    enum Torrents: Navigatable, NavigatorConfigurable {
        case list(viewModel: TorrentListViewModel)
        case detail(viewModel: TorrentDetailViewModel & NavigatorConfigurable)

        var navigator: Navigator? {
            get {
                switch self {
                case .list:
                    return nil
                case let .detail(viewModel: viewModel):
                    return viewModel.navigator
                }
            }
            set {
                switch self {
                case var .detail(viewModel: viewModel):
                    viewModel.navigator = newValue
                case .list:
                    break
                }
            }
        }

        func viewController() -> UIViewController? {
            switch self {
            case let .list(viewModel: viewModel):
                return TorrentListViewController(viewModel: viewModel)
            case let .detail(viewModel: viewModel):
                return TorrentDetailViewController(viewModel: viewModel)
            }
        }
    }
}
