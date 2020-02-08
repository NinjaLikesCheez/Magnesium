//
//  TorrentDetailSection.swift
//  Magnesium
//
//  Created by James Hurst on 2019-12-25.
//  Copyright © 2019 James Hurst. All rights reserved.
//

struct TorrentDetailSection: Equatable {
    enum Types: Equatable {
        case header
        case info
        case trackers
        case files
    }

    let type: Types
    let items: [TorrentDetailItem]
}
