//
//  TorrentListViewModel.swift
//  Magnesium
//
//  Created by James Hurst on 2019-11-12.
//  Copyright © 2019 James Hurst. All rights reserved.
//

import Combine
import ViewModel

typealias AnyTorrentListViewModel = AnyProducerViewModel<TorrentListEvent, TorrentListViewEvent, TorrentListViewState>

enum TorrentListEvent {
    case add(source: PopoverSource, linkSubject: PassthroughSubject<String, Never>)
    case detail(viewModel: AnyTorrentDetailViewModel)
    case settings
    case alert(Alert, source: PopoverSource?)
}

enum TorrentListViewEvent {
    case add(source: PopoverSource)
    case refresh
    case selectItem(index: Int)
    case settings
}

struct TorrentListViewState {
    var showAddButton: Bool = true
    var items: AnyPublisher<[AnyTorrentListItemViewModel], Never>
    var isLoading: AnyPublisher<Bool, Never>
}
