//
//  TorrentDetailViewModel.swift
//  Magnesium
//
//  Created by James Hurst on 2019-11-16.
//  Copyright © 2019 James Hurst. All rights reserved.
//

import Combine
import LinkPresentation
import UIKit
import ViewModel

typealias AnyTorrentDetailViewModel = AnyEmitterViewModel<
    TorrentDetailEvent,
    TorrentDetailViewEvent,
    TorrentDetailViewState
>

enum TorrentDetailEvent {
    case complete
    case alert(Alert, source: PopoverSource?)
    case activities([UIActivity], metadata: LPLinkMetadata)
}

enum TorrentDetailViewEvent {
    case appear
    case disappear
    case refresh
    case moreOptions(source: PopoverSource)
    case pause
    case resume
    case remove(source: PopoverSource)
}

struct TorrentDetailViewState {
    var sections: AnyPublisher<[TorrentDetailSection], Never>
    var isLoading: AnyPublisher<Bool, Never>
}
