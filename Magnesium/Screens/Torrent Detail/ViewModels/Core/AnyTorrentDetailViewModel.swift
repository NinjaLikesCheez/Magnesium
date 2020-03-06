//
//  AnyTorrentDetailViewModel.swift
//  Magnesium
//
//  Created by James Hurst on 2020-03-05.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import ViewModel

typealias AnyTorrentDetailViewModel = AnyEmitterViewModel<
    TorrentDetailEvent,
    TorrentDetailViewEvent,
    TorrentDetailViewState
>
