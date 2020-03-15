import Deluge
import Foundation

struct DelugeTorrent: StandardTorrent {
    var hash: String
    var name: String
    var standardState: TorrentState
    var dateAdded: Date
    var downloadRate: Int64
    var uploadRate: Int64
    var eta: TimeInterval
    var progress: Float
    var downloaded: Int64
    var uploaded: Int64
    var size: Int64
    var seeds: Int
    var totalSeeds: Int
    var peers: Int
    var totalPeers: Int
    var trackerStrings: [String]
    var label: String
    var downloadPath: String
}

extension DelugeTorrent {
    init?(_ torrent: Torrent) {
        guard let name = torrent.name,
            let state = torrent.state,
            let dateAdded = torrent.dateAdded,
            let downloadRate = torrent.downloadRate,
            let uploadRate = torrent.uploadRate,
            let eta = torrent.eta,
            let progress = torrent.progress,
            let downloaded = torrent.downloaded,
            let uploaded = torrent.uploaded,
            let size = torrent.size,
            let seeds = torrent.seeds,
            let totalSeeds = torrent.totalSeeds,
            let peers = torrent.peers,
            let totalPeers = torrent.totalPeers,
            let trackers = torrent.trackers,
            let label = torrent.label,
            let downloadPath = torrent.downloadPath
        else {
            return nil
        }

        hash = torrent.hash
        self.name = name
        standardState = {
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
        }()
        self.dateAdded = dateAdded
        self.downloadRate = downloadRate
        self.uploadRate = uploadRate
        self.eta = eta
        self.progress = progress
        self.downloaded = downloaded
        self.uploaded = uploaded
        self.size = size
        self.seeds = seeds
        self.totalSeeds = totalSeeds
        self.peers = peers
        self.totalPeers = totalPeers
        trackerStrings = trackers.map { $0.url }
        self.label = label
        self.downloadPath = downloadPath
    }
}
