//
//  Deluge+Mocks.swift
//  MagnesiumTests
//
//  Created by James Hurst on 2020-01-20.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import CryptoKit
import Foundation
@testable import Magnesium

extension DelugeTorrent {
    static func mock(
        hash: String = "",
        name: String = "",
        state: State = .downloading,
        dateAdded: Date = Date(),
        downloadRate: Int64 = 0,
        uploadRate: Int64 = 0,
        eta: TimeInterval = 0,
        progress: Float = 0,
        downloaded: Int64 = 0,
        uploaded: Int64 = 0,
        size: Int64 = 0,
        seeds: Int = 0,
        totalSeeds: Int = 0,
        peers: Int = 0,
        totalPeers: Int = 0,
        trackers: [String] = [],
        label: String = ""
    ) -> DelugeTorrent {
        return DelugeTorrent(
            hash: hash,
            name: name,
            state: state,
            dateAdded: dateAdded,
            downloadRate: downloadRate,
            uploadRate: uploadRate,
            eta: eta,
            progress: progress,
            downloaded: downloaded,
            uploaded: uploaded,
            size: size,
            seeds: seeds,
            totalSeeds: totalSeeds,
            peers: peers,
            totalPeers: totalPeers,
            trackers: trackers,
            label: label
        )
    }

    static func randomMock() -> DelugeTorrent {
        let uuid = UUID().uuidString
        let hash: String = {
            let hashed = Insecure.SHA1.hash(data: uuid.data(using: .utf8)!)
            return hashed.compactMap { String(format: "%02x", $0) }.joined()
        }()

        return DelugeTorrent(
            hash: hash,
            name: uuid,
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

extension DelugeTorrentFile {
    static func mock(index: Int, name: String, progress: Float = 0) -> DelugeTorrentFile {
        return DelugeTorrentFile(
            index: index,
            name: name,
            path: "",
            size: 100_000_000,
            progress: progress,
            priority: .normal
        )
    }
}
