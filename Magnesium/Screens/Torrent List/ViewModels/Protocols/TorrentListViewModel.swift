//
//  TorrentListViewModel.swift
//  Magnesium
//
//  Created by James Hurst on 2019-11-12.
//  Copyright © 2019 James Hurst. All rights reserved.
//

import Combine

enum TorrentListEvent {
    case add(source: PopoverSource)
    case detail(viewModel: TorrentDetailViewModel)
    case settings
    case alert(Alert, source: PopoverSource?)
}

protocol TorrentListViewModel: AnyObject {
    var events: AnyPublisher<TorrentListEvent, Never> { get }
    var showAddButton: Bool { get }
    var items: AnyPublisher<[AnyTorrentListItemViewModel], Never> { get }

    func refresh() -> AnyPublisher<Void, Error>
    func didSelectAdd(from source: PopoverSource)
    func didSelectItem(at index: Int)
    func didSelectSettings()
    func addLink(_ url: String)
}
