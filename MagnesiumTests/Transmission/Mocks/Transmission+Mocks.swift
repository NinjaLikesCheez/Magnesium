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
        seeds: Int = 0,
        totalSeeds: Int = 0,
        peers: Int = 0,
        totalPeers: Int = 0,
        trackers: [Transmission.Tracker] = [],
        downloadPath: String = ""
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
            seeds: seeds,
            totalSeeds: totalSeeds,
            peers: peers,
            totalPeers: totalPeers,
            trackers: trackers,
            downloadPath: downloadPath
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
            seeds: 0,
            totalSeeds: 0,
            peers: 0,
            totalPeers: 0,
            trackers: [],
            downloadPath: ""
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
