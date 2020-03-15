import Foundation

/// A Transmission torrent.
public struct Torrent: Equatable {
    /// The date the torrent was added to the server.
    public var dateAdded: Date?
    /// The file path where the torrent is being downloaded to.
    public var downloadPath: String?
    /// The download rate for the torrent in bytes/s.
    public var downloadRate: Int64?
    /// The estimated number of seconds until the torrent completes downloading.
    public var eta: TimeInterval?
    /// The SHA1 hash for the torrent.
    public var hash: String?
    /// The torrent's ID.
    public var id: Int?
    /// The name of the torrent.
    public var name: String?
    /// The number of connected peers.
    public var peers: Int?
    /// The download progress for the torrent as a percentage. This is a value between 0 and 1.
    public var progress: Float?
    /// The number of connected seeds.
    public var seeds: Int?
    /// The size of the torrent contents in bytes.
    public var size: Int64?
    /// The status of the torrent.
    public var status: Status?
    /// The number of available peers for the torrent.
    public var totalPeers: Int?
    /// The trackers used by the torrent.
    public var trackers: [Tracker]?
    /// The number of bytes uploaded for the torrent.
    public var uploaded: Int64?
    /// The upload rate for the torrent in bytes/s.
    public var uploadRate: Int64?

    /// Creates a `Torrent` with the given parameters.
    public init(
        dateAdded: Date? = nil,
        downloadPath: String? = nil,
        downloadRate: Int64? = nil,
        eta: TimeInterval? = nil,
        hash: String? = nil,
        id: Int? = nil,
        name: String? = nil,
        peers: Int? = nil,
        progress: Float? = nil,
        seeds: Int? = nil,
        size: Int64? = nil,
        status: Torrent.Status? = nil,
        totalPeers: Int? = nil,
        trackers: [Tracker]? = nil,
        uploaded: Int64? = nil,
        uploadRate: Int64? = nil
    ) {
        self.dateAdded = dateAdded
        self.downloadPath = downloadPath
        self.downloadRate = downloadRate
        self.eta = eta
        self.hash = hash
        self.id = id
        self.name = name
        self.peers = peers
        self.progress = progress
        self.seeds = seeds
        self.size = size
        self.status = status
        self.totalPeers = totalPeers
        self.trackers = trackers
        self.uploaded = uploaded
        self.uploadRate = uploadRate
    }
}

public extension Torrent {
    /// The status of a torrent.
    enum Status: Int {
        case paused = 0
        case checkQueued = 1
        case checking = 2
        case downloadQueued = 3
        case downloading = 4
        case seedQueued = 5
        case seeding = 6
        case isolated = 7
    }
}

public extension Torrent {
    /// The keys used to request `Torrent` properties.
    enum PropertyKeys: String, CaseIterable {
        case dateAdded = "addedDate"
        case downloadPath = "downloadDir"
        case downloadRate = "rateDownload"
        case eta
        case hash = "hashString"
        case id
        case name
        case peers = "peersGettingFromUs"
        case progress = "percentDone"
        case seeds = "peersSendingToUs"
        case size = "totalSize"
        case status
        case totalPeers = "peersConnected"
        case trackers = "trackerStats"
        case uploaded = "uploadedEver"
        case uploadRate = "rateUpload"
    }
}

extension Torrent {
    /// Creates a `Torrent` from a response dictionary.
    /// - Parameter dictionary: The response dictionary for the torrent.
    init(dictionary: [String: Any]) {
        func decode<Value>(_ propertyKey: PropertyKeys, _ type: Value.Type? = nil) -> Value? {
            dictionary[propertyKey.rawValue] as? Value
        }

        dateAdded = decode(.dateAdded).map(Date.init(timeIntervalSince1970:))
        downloadPath = decode(.downloadPath)
        downloadRate = decode(.downloadRate)
        eta = decode(.eta)
        hash = decode(.hash)
        id = decode(.id)
        name = decode(.name)
        peers = decode(.peers)
        progress = decode(.progress, Double.self).map(Float.init)
        seeds = decode(.seeds)
        size = decode(.size)
        status = decode(.status).flatMap(Status.init)
        totalPeers = decode(.totalPeers)
        trackers = decode(.trackers, [[String: Any]].self).flatMap { $0.compactMap(Tracker.init) }
        uploaded = decode(.uploaded)
        uploadRate = decode(.uploadRate)
    }
}
