//
//  NoopMockTorrentServerRefresher.swift
//  Magnesium
//
//  Created by James Hurst on 2019-12-20.
//  Copyright © 2019 James Hurst. All rights reserved.
//

import Combine

#if DEBUG
    struct NoopMockTorrentServerRefresher: MockTorrentServerRefreshable {
        let torrentsUpdated: AnyPublisher<[MockTorrent], Never> = Empty().eraseToAnyPublisher()

        func refresh() -> AnyPublisher<Never, Error> {
            return Empty(completeImmediately: true).eraseToAnyPublisher()
        }
    }
#endif
