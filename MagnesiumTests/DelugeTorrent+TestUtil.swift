//
//  DelugeTorrent+TestUtil.swift
//  MagnesiumTests
//
//  Created by James Hurst on 2020-01-20.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Foundation
@testable import Magnesium

extension DelugeTorrent {
    static func mock() -> DelugeTorrent {
        return DelugeTorrent(
            hash: "",
            name: "",
            state: .downloading,
            dateAdded: Date(),
            downloadRate: 0,
            uploadRate: 0,
            eta: 0,
            progress: 0,
            downloaded: 0,
            uploaded: 0,
            size: 0,
            seeds: 0,
            totalSeeds: 0,
            peers: 0,
            totalPeers: 0,
            trackers: [],
            label: ""
        )
    }
}
