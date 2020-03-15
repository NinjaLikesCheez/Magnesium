import Deluge
import Foundation

struct DelugeTorrent: StandardTorrent {
    var hash: String
    var dateAdded: Date
    var downloaded: Int64
    var downloadPath: String
    var downloadRate: Int64
    var eta: TimeInterval
    var label: String
    var name: String
    var peers: Int
    var progress: Float
    var seeds: Int
    var size: Int64
    var standardState: TorrentState
    var totalPeers: Int
    var totalSeeds: Int
    var trackerStrings: [String]
    var uploaded: Int64
    var uploadRate: Int64
}

extension DelugeTorrent {
    private static func state(for state: Torrent.State) -> TorrentState {
        switch state {
        case .downloading:
            return .downloading
        case .seeding:
            return .seeding
        case .paused:
            return .paused
        case .checking:
            return .checking
        case .queued:
            return .queued
        case .error:
            return .error
        }
    }

    init?(_ torrent: Torrent) {
        guard let dateAdded = torrent.dateAdded,
            let downloaded = torrent.downloaded,
            let downloadPath = torrent.downloadPath,
            let downloadRate = torrent.downloadRate,
            let eta = torrent.eta,
            let label = torrent.label,
            let peers = torrent.peers,
            let progress = torrent.progress,
            let seeds = torrent.seeds,
            let size = torrent.size,
            let standardState = torrent.state.map(Self.state),
            let totalPeers = torrent.totalPeers,
            let totalSeeds = torrent.totalSeeds,
            let trackerStrings = torrent.trackers?.map(\.url),
            let uploaded = torrent.uploaded,
            let uploadRate = torrent.uploadRate,
            let name = torrent.name
        else {
            return nil
        }

        hash = torrent.hash
        self.dateAdded = dateAdded
        self.downloaded = downloaded
        self.downloadPath = downloadPath
        self.downloadRate = downloadRate
        self.eta = eta
        self.label = label
        self.name = name
        self.peers = peers
        self.progress = progress
        self.seeds = seeds
        self.size = size
        self.standardState = standardState
        self.totalPeers = totalPeers
        self.totalSeeds = totalSeeds
        self.trackerStrings = trackerStrings
        self.uploaded = uploaded
        self.uploadRate = uploadRate
    }
}
