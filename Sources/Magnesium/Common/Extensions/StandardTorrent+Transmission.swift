import Transmission

extension StandardTorrent {
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
        guard let bytesUnchecked = torrent.bytesUnchecked,
              let bytesValid = torrent.bytesValid,
              let dateAdded = torrent.dateAdded,
              let downloadPath = torrent.downloadPath,
              let downloadRate = torrent.downloadRate,
              let eta = torrent.eta,
              let hash = torrent.hash,
              let name = torrent.name,
              let peers = torrent.peers,
              let progress = torrent.progress,
              let seeds = torrent.seeds,
              let size = torrent.size,
              let state = torrent.status.map(Self.state),
              let totalPeers = torrent.totalPeers,
              let trackers = torrent.trackers?.map(\.host),
              let uploaded = torrent.uploaded,
              let uploadRate = torrent.uploadRate
        else {
            return nil
        }

        downloaded = bytesUnchecked + bytesValid
        label = ""
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
        self.state = state
        self.totalPeers = totalPeers
        self.trackers = trackers
        self.uploaded = uploaded
        self.uploadRate = uploadRate
        totalSeeds = totalPeers
    }
}
