//
//  MockTorrent.swift
//  Magnesium
//
//  Created by James Hurst on 2019-11-16.
//  Copyright © 2019 James Hurst. All rights reserved.
//

import Foundation

struct MockTorrent {
    var id: Int
    var name: String
    var state: TorrentState
    var size: Int64
    var downloaded: Int64
    var uploaded: Int64
    var downloadRate: Int
    var uploadRate: Int
    var eta: TimeInterval
    var seeds: Int
    var totalSeeds: Int
    var peers: Int
    var totalPeers: Int
    var trackers: [String]
}

extension MockTorrent: TorrentExt {}
