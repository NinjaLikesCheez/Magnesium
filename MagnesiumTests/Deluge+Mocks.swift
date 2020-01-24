//
//  Deluge+Mocks.swift
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
            hash: "3f70b98c6162c02924194447e1f23e749edf7a1f",
            name: "archlinux-2020.01.01-x86_64.iso",
            state: .downloading,
            dateAdded: Date(),
            downloadRate: 1_540_527,
            uploadRate: 465_158,
            eta: 361,
            progress: 0.18983800888061523,
            downloaded: 130_583_716,
            uploaded: 56_455_257,
            size: 687_865_856,
            seeds: 70,
            totalSeeds: 832,
            peers: 2,
            totalPeers: 35,
            trackers: ["udp://tracker.archlinux.org:6969", "http://tracker.archlinux.org:6969/announce"],
            label: "Linux"
        )
    }
}

extension DelugeTorrentFile {
    static func mock(name: String = "") -> DelugeTorrentFile {
        return DelugeTorrentFile(
            name: name,
            index: 0,
            path: "/\(name)",
            size: 100_000_000,
            progress: 85.29,
            priority: .normal
        )
    }
}
