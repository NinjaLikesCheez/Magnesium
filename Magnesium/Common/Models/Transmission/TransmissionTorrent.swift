import Foundation
import Transmission

/// A Transmission torrent.
struct TransmissionTorrent: StandardTorrent {
    var dateAdded: Date
    var downloadPath: String
    var downloadRate: Int64
    var eta: TimeInterval
    var hash: String
    var name: String
    var peers: Int
    var progress: Float
    var seeds: Int
    var size: Int64
    var standardState: TorrentState
    var totalPeers: Int
    var trackerStrings: [String]
    var uploaded: Int64
    var uploadRate: Int64

    var downloaded: Int64 {
        Int64(Float(size) * progress)
    }

    var totalSeeds: Int {
        totalPeers
    }

    var label: String {
        ""
    }
}

extension TransmissionTorrent {
    private static func state(for status: Torrent.Status) -> TorrentState {
        switch status {
        case .paused:
            return .paused
        case .checkQueued:
            return .queued
        case .checking:
            return .checking
        case .downloadQueued:
            return .queued
        case .downloading:
            return .downloading
        case .seedQueued:
            return .queued
        case .seeding:
            return .seeding
        case .isolated:
            return .error
        }
    }

    init?(_ torrent: Torrent) {
        guard let dateAdded = torrent.dateAdded,
            let downloadPath = torrent.downloadPath,
            let downloadRate = torrent.downloadRate,
            let eta = torrent.eta,
            let hash = torrent.hash,
            let name = torrent.name,
            let peers = torrent.peers,
            let progress = torrent.progress,
            let seeds = torrent.seeds,
            let size = torrent.size,
            let standardState = torrent.status.map(Self.state),
            let totalPeers = torrent.totalPeers,
            let trackerStrings = torrent.trackers?.map(\.host),
            let uploaded = torrent.uploaded,
            let uploadRate = torrent.uploadRate
        else {
            return nil
        }

        self.dateAdded = dateAdded
        self.downloadPath = downloadPath
        self.downloadRate = downloadRate
        self.eta = eta
        self.hash = hash
        self.name = name
        self.peers = peers
        self.progress = progress
        self.seeds = seeds
        self.size = size
        self.standardState = standardState
        self.totalPeers = totalPeers
        self.trackerStrings = trackerStrings
        self.uploaded = uploaded
        self.uploadRate = uploadRate
    }
}
