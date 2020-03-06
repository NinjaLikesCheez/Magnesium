protocol StandardTorrentFile {
    var index: Int { get }
    var name: String { get }
    var size: Int64 { get }
    var progress: Float { get }
}
