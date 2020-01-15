//
//  TorrentListViewModel.swift
//  Magnesium
//
//  Created by James Hurst on 2019-11-12.
//  Copyright © 2019 James Hurst. All rights reserved.
//

import Combine
import Navigator
import Preferences

protocol TorrentListViewModel: AnyObject {
    var navigator: Navigator? { get set }
    var items: AnyPublisher<[AnyTorrentListItemViewModel], Never> { get }

    func refresh() -> AnyPublisher<Never, Error>
    func didSelectSettings()
    func didSelectItem(at index: Int)
}

protocol TorrentListViewModelExt: TorrentListViewModel {
    var preferences: Preferences { get }
}

extension TorrentListViewModelExt {
    func didSelectSettings() {
        let viewModel = DefaultSettingsViewModel(preferences: preferences)
        let screen = NavigationControllerScreen(Screens.settings(viewModel: viewModel))
        viewModel.navigator = navigator?.present(screen, animated: true)
    }
}
