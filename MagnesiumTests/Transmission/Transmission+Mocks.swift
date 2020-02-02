//
//  Transmission+Mocks.swift
//  MagnesiumTests
//
//  Created by James Hurst on 2020-02-01.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import CryptoKit
import Foundation
@testable import Magnesium
import Transmission

extension TransmissionTorrent {
    static func mock(
        id: Int = 0,
        hash: String = "",
        name: String = "",
        status: Status = .downloading,
        dateAdded: Date = Date(),
        downloadRate: Int64 = 0,
        uploadRate: Int64 = 0,
        eta: TimeInterval = 0,
        progress: Float = 0,
        downloaded: Int64 = 0,
        uploaded: Int64 = 0,
        size: Int64 = 0,
        trackers: [Transmission.Tracker] = []
    ) -> TransmissionTorrent {
        return TransmissionTorrent(
            id: id,
            hash: hash,
            name: name,
            status: status,
            dateAdded: dateAdded,
            downloadRate: downloadRate,
            uploadRate: uploadRate,
            eta: eta,
            progress: progress,
            downloaded: downloaded,
            uploaded: uploaded,
            size: size,
            trackers: trackers
        )
    }

    static func randomMock() -> TransmissionTorrent {
        let uuid = UUID().uuidString
        let hash: String = {
            let hashed = Insecure.SHA1.hash(data: uuid.data(using: .utf8)!)
            return hashed.compactMap { String(format: "%02x", $0) }.joined()
        }()

        return TransmissionTorrent(
            id: hash.hashValue,
            hash: hash,
            name: uuid,
            status: .downloading,
            dateAdded: Date(),
            downloadRate: 0,
            uploadRate: 0,
            eta: 0,
            progress: 0,
            downloaded: 0,
            uploaded: 0,
            size: 0,
            trackers: []
        )
    }
}
