import Foundation

/// A Transmission torrent.
public struct Torrent {
    /// The statuses of a torrent.
    public enum Status: Int {
        case paused = 0
        case checkQueued = 1
        case checking = 2
        case downloadQueued = 3
        case downloading = 4
        case seedQueued = 5
        case seeding = 6
        case isolated = 7
    }

    /// The torrent's ID.
    public var id: Int
    /// The torrent's hash.
    public var hash: String
    /// The torrent's name.
    public var name: String
    /// The torrent's current state.
    public var status: Status
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
    /// The number of connected seeds.
    public var seeds: Int
    /// The total number of seeds.
    public var totalSeeds: Int
    /// The number of connected peers.
    public var peers: Int
    /// The total number of peers.
    public var totalPeers: Int
    /// The torrent's trackers.
    public var trackers: [Tracker]
    /// The torrent's download path.
    public var downloadPath: String

    /// Creates a `Torrent` with the given parameters.
    public init(
        id: Int,
        hash: String,
        name: String,
        status: Status,
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
        trackers: [Tracker],
        downloadPath: String
    ) {
        self.id = id
        self.hash = hash
        self.name = name
        self.status = status
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
        self.downloadPath = downloadPath
    }
}

extension Torrent {
    init?(dictionary: [String: Any]) {
        guard let id = dictionary["id"] as? Int,
            let hash = dictionary["hashString"] as? String,
            let name = dictionary["name"] as? String,
            let statusCode = dictionary["status"] as? Int,
            let status = Status(rawValue: statusCode),
            let addedDate = dictionary["addedDate"] as? TimeInterval,
            let downloadRate = dictionary["rateDownload"] as? Int64,
            let uploadRate = dictionary["rateUpload"] as? Int64,
            let eta = dictionary["eta"] as? TimeInterval,
            let progress = dictionary["percentDone"] as? Double,
            let downloaded = dictionary["downloadedEver"] as? Int64,
            let uploaded = dictionary["uploadedEver"] as? Int64,
            let size = dictionary["totalSize"] as? Int64,
            let seeds = dictionary["peersSendingToUs"] as? Int,
            let peers = dictionary["peersGettingFromUs"] as? Int,
            let peersConnected = dictionary["peersConnected"] as? Int,
            let trackers = (dictionary["trackerStats"] as? [[String: Any]])?.compactMap({ Tracker(dictionary: $0) }),
            let downloadPath = dictionary["downloadDir"] as? String
        else {
            return nil
        }

        self.id = id
        self.hash = hash
        self.name = name
        self.status = status
        dateAdded = Date(timeIntervalSince1970: addedDate)
        self.downloadRate = downloadRate
        self.uploadRate = uploadRate
        self.eta = eta
        self.progress = Float(progress)
        self.downloaded = downloaded
        self.uploaded = uploaded
        self.size = size
        self.seeds = seeds
        totalSeeds = peersConnected
        self.peers = peers
        totalPeers = peersConnected
        self.trackers = trackers
        self.downloadPath = downloadPath
    }
}
