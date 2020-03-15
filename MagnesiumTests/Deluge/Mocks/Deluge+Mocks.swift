import CryptoKit
import Deluge
import Foundation
@testable import Magnesium

private func randomHash() -> String {
    let uuid = UUID().uuidString
    let hashed = Insecure.SHA1.hash(data: uuid.data(using: .utf8)!)
    return hashed.compactMap { String(format: "%02x", $0) }.joined()
}

extension Torrent {
    static func mock(
        dateAdded: Date = Date(),
        downloaded: Int64 = 0,
        downloadPath: String = "/",
        downloadRate: Int64 = 0,
        eta: TimeInterval = 0,
        hash: String = randomHash(),
        label: String = "",
        name: String = "",
        peers: Int = 0,
        progress: Float = 0,
        seeds: Int = 0,
        size: Int64 = 0,
        state: Torrent.State = .downloading,
        totalPeers: Int = 0,
        totalSeeds: Int = 0,
        trackers: [Tracker] = [],
        uploaded: Int64 = 0,
        uploadRate: Int64 = 0
    ) -> Self {
        return .init(
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

extension DelugeTorrent {
    static func mock(
        hash: String = randomHash(),
        dateAdded: Date = Date(),
        downloaded: Int64 = 0,
        downloadPath: String = "/",
        downloadRate: Int64 = 0,
        eta: TimeInterval = 0,
        label: String = "",
        name: String = "",
        peers: Int = 0,
        progress: Float = 0,
        seeds: Int = 0,
        size: Int64 = 0,
        standardState: TorrentState = .downloading,
        totalPeers: Int = 0,
        totalSeeds: Int = 0,
        trackerStrings: [String] = [],
        uploaded: Int64 = 0,
        uploadRate: Int64 = 0
    ) -> Self {
        return .init(
            hash: hash,
            dateAdded: dateAdded,
            downloaded: downloaded,
            downloadPath: downloadPath,
            downloadRate: downloadRate,
            eta: eta,
            label: label,
            name: name,
            peers: peers,
            progress: progress,
            seeds: seeds,
            size: size,
            standardState: standardState,
            totalPeers: totalPeers,
            totalSeeds: totalSeeds,
            trackerStrings: trackerStrings,
            uploaded: uploaded,
            uploadRate: uploadRate
        )
    }
}

extension DelugeLabel {
    static func mock(name: String = "", count: Int = 0) -> DelugeLabel {
        return DelugeLabel(name: name, count: count)
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
