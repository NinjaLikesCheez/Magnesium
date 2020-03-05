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

    /// The date the torrent was added to the server.
    public var dateAdded: Date?
    /// The amount of data currently downloaded for the torrent in bytes.
    public var downloaded: Int64?
    /// The torrent's download path.
    public var downloadPath: String?
    /// The torrent's current download rate in bytes/s.
    public var downloadRate: Int64?
    /// The torrent's current ETA.
    public var eta: TimeInterval?
    /// The torrent's hash.
    public var hash: String
    /// The torrent's label.
    public var label: String?
    /// The torrent's name.
    public var name: String?
    /// The number of connected peers.
    public var peers: Int?
    /// The torrent's current progress. This is a value between 0 and 1.
    public var progress: Float?
    /// The number of connected seeds.
    public var seeds: Int?
    /// The size of the torrent in bytes.
    public var size: Int64?
    /// The torrent's current state.
    public var state: State?
    /// The total number of peers.
    public var totalPeers: Int?
    /// The total number of seeds.
    public var totalSeeds: Int?
    /// The torrent's trackers.
    public var trackers: [Tracker]?
    /// The amount of data currently uploaded for the torrent in bytes.
    public var uploaded: Int64?
    /// The torrent's current upload rate in bytes/s.
    public var uploadRate: Int64?

    /// Creates a `Torrent` with the given parameters.
    public init(
        dateAdded: Date? = nil,
        downloaded: Int64? = nil,
        downloadPath: String? = nil,
        downloadRate: Int64? = nil,
        eta: TimeInterval? = nil,
        hash: String,
        label: String? = nil,
        name: String? = nil,
        peers: Int? = nil,
        progress: Float? = nil,
        seeds: Int? = nil,
        size: Int64? = nil,
        state: Torrent.State? = nil,
        totalPeers: Int? = nil,
        totalSeeds: Int? = nil,
        trackers: [Tracker]? = nil,
        uploaded: Int64? = nil,
        uploadRate: Int64? = nil
    ) {
        self.dateAdded = dateAdded
        self.downloaded = downloaded
        self.downloadPath = downloadPath
        self.downloadRate = downloadRate
        self.eta = eta
        self.hash = hash
        self.label = label
        self.name = name
        self.peers = peers
        self.progress = progress
        self.seeds = seeds
        self.size = size
        self.state = state
        self.totalPeers = totalPeers
        self.totalSeeds = totalSeeds
        self.trackers = trackers
        self.uploaded = uploaded
        self.uploadRate = uploadRate
    }
}

extension Torrent {
    /// Creates a `Torrent` from a response dictionary.
    /// - Parameters:
    ///   - hash: The torrent's hash.
    ///   - dictionary: The response dictionary for the torrent.
    init(hash: String, dictionary: [String: Any]) {
        dateAdded = (dictionary["time_added"] as? TimeInterval).map(Date.init(timeIntervalSince1970:))
        downloaded = dictionary["total_done"] as? Int64
        downloadPath = dictionary["download_location"] as? String
        downloadRate = dictionary["download_payload_rate"] as? Int64
        eta = dictionary["eta"] as? TimeInterval
        self.hash = hash
        label = dictionary["label"] as? String
        name = dictionary["name"] as? String
        peers = dictionary["num_peers"] as? Int
        progress = (dictionary["progress"] as? Float).map { $0 / 100 }
        seeds = dictionary["num_seeds"] as? Int
        size = dictionary["total_size"] as? Int64
        state = (dictionary["state"] as? String).flatMap {
            switch $0 {
            case "Downloading":
                return .downloading
            case "Seeding":
                return .seeding
            case "Paused":
                return .paused
            case "Checking":
                return .checking
            case "Queued":
                return .queued
            case "Error":
                return .error
            default:
                return nil
            }
        }
        totalPeers = dictionary["total_peers"] as? Int
        totalSeeds = dictionary["total_seeds"] as? Int
        trackers = (dictionary["trackers"] as? [[String: Any]])?.compactMap(Tracker.init)
        uploaded = dictionary["total_uploaded"] as? Int64
        uploadRate = dictionary["upload_payload_rate"] as? Int64
    }
}
