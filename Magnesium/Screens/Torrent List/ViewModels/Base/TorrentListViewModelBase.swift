//
//  TorrentListViewModel.swift
//  Magnesium
//
//  Created by James Hurst on 2019-11-12.
//  Copyright © 2019 James Hurst. All rights reserved.
//

import Combine
import ViewModel

typealias AnyTorrentListViewModel = AnyEmitterViewModel<TorrentListEvent, TorrentListViewEvent, TorrentListViewState>

enum TorrentListEvent {
    case add(source: PopoverSource, linkSubject: PassthroughSubject<String, Never>)
    case filter(source: PopoverSource)
    case detail(viewModel: AnyTorrentDetailViewModel)
    case settings
    case alert(Alert, source: PopoverSource?)
}

enum TorrentListViewEvent {
    case refresh
    case addSelected(source: PopoverSource)
    case filterSelected(source: PopoverSource)
    case itemSelected(index: Int)
    case settingsSelected
}

struct TorrentListViewState {
    var showAddButton: Bool = true
    var items: AnyPublisher<[AnyTorrentListItemViewModel], Never>
    var isLoading: AnyPublisher<Bool, Never>
}
