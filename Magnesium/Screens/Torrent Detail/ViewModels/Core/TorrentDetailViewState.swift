//
//  TorrentDetailViewState.swift
//  Magnesium
//
//  Created by James Hurst on 2019-11-16.
//  Copyright © 2019 James Hurst. All rights reserved.
//

import Combine

struct TorrentDetailViewState {
    var hash: String
    var sections: AnyPublisher<[TorrentDetailSection], Never>
    var isRefreshing: AnyPublisher<Bool, Never>
}
