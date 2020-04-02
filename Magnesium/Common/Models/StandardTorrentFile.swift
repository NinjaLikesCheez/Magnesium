struct StandardTorrentFile {
    var index: Int
    var name: String
    var size: Int64
    var progress: Float
    var priority: TorrentPriority
}

extension StandardTorrentFile: Equatable {}
extension StandardTorrentFile: Hashable {}
