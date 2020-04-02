struct StandardTorrentFile {
    var index: Int
    var name: String
    var size: Int64
    var progress: Float
}

extension StandardTorrentFile: Equatable {}
