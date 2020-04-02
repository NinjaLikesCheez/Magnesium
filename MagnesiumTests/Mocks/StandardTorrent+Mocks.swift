import CryptoKit
import Foundation
@testable import Magnesium

extension StandardTorrent {
    static func createHash() -> String {
        let data = UUID().uuidString.data(using: .utf8)!
        let hashed = Insecure.SHA1.hash(data: data)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }

    static func mock(
        dateAdded: Date = Date(),
        downloaded: Int64 = 0,
        downloadPath: String = "",
        downloadRate: Int64 = 0,
        eta: TimeInterval = 0,
        hash: String = Self.createHash(),
        label: String = "",
        name: String = "",
        peers: Int = 0,
        progress: Float = 0,
        seeds: Int = 0,
        size: Int64 = 0,
        state: TorrentState = .downloading,
        totalPeers: Int = 0,
        totalSeeds: Int = 0,
        trackers: [String] = [],
        uploaded: Int64 = 0,
        uploadRate: Int64 = 0
    ) -> Self {
        self.init(
            dateAdded: dateAdded,
            downloaded: downloaded,
            downloadPath: downloadPath,
            downloadRate: downloadRate,
            eta: eta,
            hash: hash,
            label: label,
            name: name,
            peers: peers,
            progress: progress,
            seeds: seeds,
            size: size,
            state: state,
            totalPeers: totalPeers,
            totalSeeds: totalSeeds,
            trackers: trackers,
            uploaded: uploaded,
            uploadRate: uploadRate
        )
    }
}
