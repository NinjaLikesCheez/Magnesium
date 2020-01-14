//
//  Navigator+Servers.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-14.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Navigator
import Preferences

extension Navigator {
    func showFirstServer(preferences: Preferences) {
        let viewModel = preferences.getServers()
            .compactMap { $0.listViewModel(preferences: preferences) }
            .last
            ?? EmptyTorrentListViewModel(preferences: preferences)
        viewModel.navigator = showMaster(NavigationControllerScreen(Screens.torrentList(viewModel: viewModel)))
    }
}
