//
//  TorrentDetailFileViewModel.swift
//  Magnesium
//
//  Created by James Hurst on 2019-12-30.
//  Copyright © 2019 James Hurst. All rights reserved.
//

import Combine
import ViewModel

typealias AnyTorrentDetailFileViewModel = AnyViewModel<Never, TorrentDetailFileViewState>

struct TorrentDetailFileViewState {
    var name: String
    var size: AnyPublisher<String, Never>
    var progress: AnyPublisher<String, Never>
}
