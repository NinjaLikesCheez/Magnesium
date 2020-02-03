/// A Transmission torrent file.
public struct TorrentFile {
    /// The file's index.
    public let index: Int
    /// The file name.
    public let name: String
    /// The file's size in bytes.
    public let size: Int64
    /// The number of bytes that have been downloaded.
    public let downloaded: Int64
    /// The file's download priority.
    public let priority: Priority
    /// Whether the file is marked as wanted or unwanted.
    public let isWanted: Bool

    public init(index: Int, name: String, size: Int64, downloaded: Int64, priority: Priority, isWanted: Bool) {
        self.index = index
        self.name = name
        self.size = size
        self.downloaded = downloaded
        self.priority = priority
        self.isWanted = isWanted
    }
}

extension TorrentFile {
    init?(index: Int, file: [String: Any], stats: [String: Any]) {
        guard let name = file["name"] as? String,
            let size = file["length"] as? Int64,
            let downloaded = file["bytesCompleted"] as? Int64,
            let priority = stats["priority"] as? Int,
            let isWanted = stats["wanted"] as? Bool
        else {
            return nil
        }

        self.index = index
        self.name = name
        self.size = size
        self.downloaded = downloaded
        self.priority = Priority(priority)
        self.isWanted = isWanted
    }
}
