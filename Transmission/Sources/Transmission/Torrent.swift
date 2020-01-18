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
    public let id: Int
    /// The torrent's hash.
    public let hash: String
    /// The torrent's name.
    public let name: String
    /// The torrent's current state.
    public let status: Status
    /// The date the torrent was added to the server.
    public let dateAdded: Date
    /// The torrent's current download rate in bytes/s.
    public let downloadRate: Int
    /// The torrent's current upload rate in bytes/s.
    public let uploadRate: Int
    /// The torrent's current ETA.
    public let eta: TimeInterval
    /// The torrent's current progress.
    public let progress: Float
    /// The amount of data currently downloaded for the torrent in bytes.
    public let downloaded: Int64
    /// The amount of data currently uploaded for the torrent in bytes.
    public let uploaded: Int64
    /// The size of the torrent in bytes.
    public let size: Int64
    /// THe torrent's trackers.
    public let trackers: [Tracker]

    public init(
        id: Int,
        hash: String,
        name: String,
        status: Status,
        dateAdded: Date,
        downloadRate: Int,
        uploadRate: Int,
        eta: TimeInterval,
        progress: Float,
        downloaded: Int64,
        uploaded: Int64,
        size: Int64,
        trackers: [Tracker]
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
        self.trackers = trackers
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
            let downloadRate = dictionary["rateDownload"] as? Int,
            let uploadRate = dictionary["rateUpload"] as? Int,
            let eta = dictionary["eta"] as? TimeInterval,
            let progress = dictionary["percentDone"] as? Double,
            let downloaded = dictionary["downloadedEver"] as? Int64,
            let uploaded = dictionary["uploadedEver"] as? Int64,
            let size = dictionary["totalSize"] as? Int64,
            let trackers = (dictionary["trackerStats"] as? [[String: Any]])?
            .compactMap({ Tracker(dictionary: $0) })
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
        self.trackers = trackers
    }
}
