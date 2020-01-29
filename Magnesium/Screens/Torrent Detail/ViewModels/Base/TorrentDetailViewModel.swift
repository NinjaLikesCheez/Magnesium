//
//  TorrentDetailViewModel.swift
//  Magnesium
//
//  Created by James Hurst on 2019-11-16.
//  Copyright © 2019 James Hurst. All rights reserved.
//

import Combine

typealias AnyTorrentDetailViewModel = AnyProducerViewModel<
    TorrentDetailEvent,
    TorrentDetailViewEvent,
    TorrentDetailViewState
>

enum TorrentDetailEvent {
    case complete
    case alert(Alert, source: PopoverSource?)
}

enum TorrentDetailViewEvent {
    case appear
    case disappear
    case refresh
    case moreOptions(PopoverSource)
    case pause
    case resume
    case remove(PopoverSource)
}

struct TorrentDetailViewState {
    var sections: AnyPublisher<[TorrentDetailSection], Never>
    var isLoading: AnyPublisher<Bool, Never>
}
