import Foundation

/// A Deluge torrent.
public struct Torrent {
    /// The states of a torrent.
    public enum State {
        case downloading
        case seeding
        case paused
        case checking
        case queued
        case error
    }

    /// The torrent's hash.
    public var hash: String
    /// The torrent's name.
    public var name: String
    /// The torrent's current state.
    public var state: State
    /// The date the torrent was added to the server.
    public var dateAdded: Date
    /// The torrent's current download rate in bytes/s.
    public var downloadRate: Int64
    /// The torrent's current upload rate in bytes/s.
    public var uploadRate: Int64
    /// The torrent's current ETA.
    public var eta: TimeInterval
    /// The torrent's current progress.
    public var progress: Float
    /// The amount of data currently downloaded for the torrent in bytes.
    public var downloaded: Int64
    /// The amount of data currently uploaded for the torrent in bytes.
    public var uploaded: Int64
    /// The size of the torrent in bytes.
    public var size: Int64
    /// The number of seeds currently connected to.
    public var seeds: Int
    /// The total number of seeds currently available.
    public var totalSeeds: Int
    /// The number of peers currently connected to.
    public var peers: Int
    /// The total number of peers currently available.
    public var totalPeers: Int
    /// The torrent's trackers.
    public var trackers: [String]
    /// The torrent's label.
    public var label: String

    public init(
        hash: String,
        name: String,
        state: State,
        dateAdded: Date,
        downloadRate: Int64,
        uploadRate: Int64,
        eta: TimeInterval,
        progress: Float,
        downloaded: Int64,
        uploaded: Int64,
        size: Int64,
        seeds: Int,
        totalSeeds: Int,
        peers: Int,
        totalPeers: Int,
        trackers: [String],
        label: String
    ) {
        self.hash = hash
        self.name = name
        self.state = state
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
        self.trackers = trackers
        self.label = label
    }
}

extension Torrent {
    init?(hash: String, dictionary: [String: Any]) {
        guard let name = dictionary["name"] as? String,
            let stateString = dictionary["state"] as? String,
            let timeAdded = dictionary["time_added"] as? TimeInterval,
            let downloadRate = dictionary["download_payload_rate"] as? Int64,
            let uploadRate = dictionary["upload_payload_rate"] as? Int64,
            let eta = dictionary["eta"] as? TimeInterval,
            let progress = dictionary["progress"] as? Float,
            let downloaded = dictionary["total_done"] as? Int64,
            let uploaded = dictionary["total_uploaded"] as? Int64,
            let size = dictionary["total_size"] as? Int64,
            let seeds = dictionary["num_seeds"] as? Int,
            let totalSeeds = dictionary["total_seeds"] as? Int,
            let peers = dictionary["num_peers"] as? Int,
            let totalPeers = dictionary["total_peers"] as? Int,
            let trackers = (dictionary["trackers"] as? [[String: Any]])?.compactMap({ $0["url"] as? String }),
            let label = dictionary["label"] as? String
        else {
            return nil
        }

        switch stateString {
        case "Downloading":
            state = .downloading
        case "Seeding":
            state = .seeding
        case "Paused":
            state = .paused
        case "Checking":
            state = .checking
        case "Queued":
            state = .queued
        case "Error":
            state = .error
        default:
            return nil
        }

        self.hash = hash
        self.name = name
        dateAdded = Date(timeIntervalSince1970: timeAdded)
        self.downloadRate = downloadRate
        self.uploadRate = uploadRate
        self.eta = eta
        self.progress = progress / 100
        self.downloaded = downloaded
        self.uploaded = uploaded
        self.size = size
        self.seeds = seeds
        self.totalSeeds = totalSeeds
        self.peers = peers
        self.totalPeers = totalPeers
        self.trackers = trackers
        self.label = label
    }
}
