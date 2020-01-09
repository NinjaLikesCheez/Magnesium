//
//  MockTorrentServerRefreshable.swift
//  Magnesium
//
//  Created by James Hurst on 2019-12-20.
//  Copyright © 2019 James Hurst. All rights reserved.
//

import Combine

protocol MockTorrentServerRefreshable {
    var torrentsUpdated: AnyPublisher<[MockTorrent], Never> { get }
    func refresh() -> AnyPublisher<Never, Error>
}
