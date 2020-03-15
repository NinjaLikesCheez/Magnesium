import CryptoKit
import Foundation
@testable import Magnesium
import Transmission

private func randomHash() -> String {
    let uuid = UUID().uuidString
    let hashed = Insecure.SHA1.hash(data: uuid.data(using: .utf8)!)
    return hashed.compactMap { String(format: "%02x", $0) }.joined()
}

extension Torrent {
    static func mock(
        dateAdded: Date = Date(),
        downloadPath: String = "/",
        downloadRate: Int64 = 0,
        eta: TimeInterval = 0,
        hash: String = randomHash(),
        name: String = "",
        peers: Int = 0,
        progress: Float = 0,
        seeds: Int = 0,
        size: Int64 = 0,
        status: Torrent.Status = .downloading,
        totalPeers: Int = 0,
        trackers: [Tracker] = [],
        uploaded: Int64 = 0,
        uploadRate: Int64 = 0
    ) -> Self {
        return .init(
            dateAdded: dateAdded,
            downloadPath: downloadPath,
            downloadRate: downloadRate,
            eta: eta,
            hash: hash,
            name: name,
            peers: peers,
            progress: progress,
            seeds: seeds,
            size: size,
            status: status,
            totalPeers: totalPeers,
            trackers: trackers,
            uploaded: uploadRate,
            uploadRate: uploadRate
        )
    }
}

extension TransmissionTorrent {
    static func mock(
        dateAdded: Date = Date(),
        downloadPath: String = "/",
        downloadRate: Int64 = 0,
        eta: TimeInterval = 0,
        hash: String = randomHash(),
        name: String = "",
        peers: Int = 0,
        progress: Float = 0,
        seeds: Int = 0,
        size: Int64 = 0,
        standardState: TorrentState = .downloading,
        totalPeers: Int = 0,
        trackerStrings: [String] = [],
        uploaded: Int64 = 0,
        uploadRate: Int64 = 0
    ) -> Self {
        return .init(
            dateAdded: dateAdded,
            downloadPath: downloadPath,
            downloadRate: downloadRate,
            eta: eta,
            hash: hash,
            name: name,
            peers: peers,
            progress: progress,
            seeds: seeds,
            size: size,
            standardState: standardState,
            totalPeers: totalPeers,
            trackerStrings: trackerStrings,
            uploaded: uploaded,
            uploadRate: uploadRate
        )
    }
}

extension TransmissionTorrentFile {
    static func mock(
        index: Int = 0,
        name: String = "",
        size: Int64 = 0,
        downloaded: Int64 = 0,
        priority: Priority = .normal,
        isWanted: Bool = true
    ) -> TransmissionTorrentFile {
        return TransmissionTorrentFile(
            index: index,
            name: name,
            size: size,
            downloaded: downloaded,
            priority: priority,
            isWanted: isWanted
        )
    }
}
