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
    var size: Int
    var downloaded: Int
    var uploaded: Int
    var downloadRate: Int
    var uploadRate: Int
    var eta: TimeInterval
    var seeds: Int
    var totalSeeds: Int
    var peers: Int
    var totalPeers: Int
    var trackers: [String]

    var ratio: Double {
        return Double(uploaded) / Double(downloaded)
    }

    var progress: Float {
        return size != 0 ? Float(downloaded) / Float(size) : 0
    }
}

extension MockTorrent {
    var speedDisplayString: String {
        if state == .downloading {
            return """
            ↓ \(ByteFormatter.string(fromByteCount: downloadRate))/s \
            ↑ \(ByteFormatter.string(fromByteCount: uploadRate))/s
            """
        } else if state == .seeding {
            return "↑ \(ByteFormatter.string(fromByteCount: uploadRate))/s"
        } else {
            return ""
        }
    }

    var progressDisplayString: String {
        return """
        \(ByteFormatter.string(fromByteCount: downloaded)) / \
        \(ByteFormatter.string(fromByteCount: size)) \
        (\(Int(progress * 100))%)
        """
    }
}
