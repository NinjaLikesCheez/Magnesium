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
    public var name: String?
    /// The torrent's current state.
    public var state: State?
    /// The date the torrent was added to the server.
    public var dateAdded: Date?
    /// The torrent's current download rate in bytes/s.
    public var downloadRate: Int64?
    /// The torrent's current upload rate in bytes/s.
    public var uploadRate: Int64?
    /// The torrent's current ETA.
    public var eta: TimeInterval?
    /// The torrent's current progress. This is a value between 0 and 1.
    public var progress: Float?
    /// The amount of data currently downloaded for the torrent in bytes.
    public var downloaded: Int64?
    /// The amount of data currently uploaded for the torrent in bytes.
    public var uploaded: Int64?
    /// The size of the torrent in bytes.
    public var size: Int64?
    /// The number of connected seeds.
    public var seeds: Int?
    /// The total number of seeds.
    public var totalSeeds: Int?
    /// The number of connected peers.
    public var peers: Int?
    /// The total number of peers.
    public var totalPeers: Int?
    /// The torrent's trackers.
    public var trackers: [String]?
    /// The torrent's label.
    public var label: String?
    /// The torrent's download path.
    public var downloadPath: String?

    /// Creates a `Torrent` with the given parameters.
    public init(
        hash: String,
        name: String? = nil,
        state: State? = nil,
        dateAdded: Date? = nil,
        downloadRate: Int64? = nil,
        uploadRate: Int64? = nil,
        eta: TimeInterval? = nil,
        progress: Float? = nil,
        downloaded: Int64? = nil,
        uploaded: Int64? = nil,
        size: Int64? = nil,
        seeds: Int? = nil,
        totalSeeds: Int? = nil,
        peers: Int? = nil,
        totalPeers: Int? = nil,
        trackers: [String]? = nil,
        label: String? = nil,
        downloadPath: String? = nil
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
        self.downloadPath = downloadPath
    }
}

extension Torrent {
    /// Creates a `Torrent` from a response dictionary.
    /// - Parameters:
    ///   - hash: The torrent's hash.
    ///   - dictionary: The response dictionary for the torrent.
    init(hash: String, dictionary: [String: Any]) {
        self.hash = hash
        name = dictionary["name"] as? String
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
        dateAdded = (dictionary["time_added"] as? TimeInterval).map(Date.init(timeIntervalSince1970:))
        downloadRate = dictionary["download_payload_rate"] as? Int64
        uploadRate = dictionary["upload_payload_rate"] as? Int64
        eta = dictionary["eta"] as? TimeInterval
        progress = (dictionary["progress"] as? Float).map { $0 / 100 }
        downloaded = dictionary["total_done"] as? Int64
        uploaded = dictionary["total_uploaded"] as? Int64
        size = dictionary["total_size"] as? Int64
        seeds = dictionary["num_seeds"] as? Int
        totalSeeds = dictionary["total_seeds"] as? Int
        peers = dictionary["num_peers"] as? Int
        totalPeers = dictionary["total_peers"] as? Int
        trackers = (dictionary["trackers"] as? [[String: Any]])?.compactMap { $0["url"] as? String }
        label = dictionary["label"] as? String
        downloadPath = dictionary["download_location"] as? String
    }
}
