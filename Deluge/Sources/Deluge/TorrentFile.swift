/// A Deluge torrent file.
public struct TorrentFile {
    /// The file name.
    public let name: String
    /// The file's index.
    public let index: Int
    /// The file's path.
    public let path: String
    /// The file's size in bytes.
    public let size: Int64
    /// The file's current progress.
    public let progress: Float
    /// The file's download priority.
    public let priority: Int

    public init(name: String, index: Int, path: String, size: Int64, progress: Float, priority: Int) {
        self.name = name
        self.index = index
        self.path = path
        self.size = size
        self.progress = progress
        self.priority = priority
    }
}

extension TorrentFile {
    init?(name: String, dictionary: [String: Any]) {
        guard let index = dictionary["index"] as? Int,
            let path = dictionary["path"] as? String,
            let size = dictionary["size"] as? Int64,
            let progress = dictionary["progress"] as? Float,
            let priority = dictionary["priority"] as? Int
        else {
            return nil
        }

        self.name = name
        self.index = index
        self.path = path
        self.size = size
        self.progress = progress
        self.priority = priority
    }
}
