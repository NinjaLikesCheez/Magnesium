//
//  TorrentListViewModel.swift
//  Magnesium
//
//  Created by James Hurst on 2019-11-12.
//  Copyright © 2019 James Hurst. All rights reserved.
//

import Combine
import Preferences

protocol TorrentListViewModel: AnyObject {
    var coordinator: TorrentListCoordinator? { get }
    var items: AnyPublisher<[AnyTorrentListItemViewModel], Never> { get }

    func refresh() -> AnyPublisher<Never, Error>
    func didSelectSettings()
    func didSelectItem(at index: Int)
}

extension TorrentListViewModel {
    func didSelectSettings() {
        coordinator?.showSettings()
    }
}
