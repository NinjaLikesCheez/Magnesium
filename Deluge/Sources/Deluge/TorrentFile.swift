/// A Deluge torrent file.
public struct TorrentFile {
    /// The file's index.
    public var index: Int
    /// The file name.
    public var name: String
    /// The file's path.
    public var path: String
    /// The file's size in bytes.
    public var size: Int64
    /// The file's current progress.
    public var progress: Float
    /// The file's download priority.
    public var priority: Priority

    public init(index: Int, name: String, path: String, size: Int64, progress: Float, priority: Priority) {
        self.index = index
        self.name = name
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

        self.index = index
        self.name = name
        self.path = path
        self.size = size
        self.progress = progress
        self.priority = Priority(priority)
    }
}
