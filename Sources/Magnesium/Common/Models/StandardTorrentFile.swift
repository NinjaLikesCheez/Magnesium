struct StandardTorrentFile {
    var index: Int
    var name: String
    var size: Int64
    var progress: Float
    var priority: TorrentPriority
}

extension StandardTorrentFile: Equatable {}
extension StandardTorrentFile: Hashable {}

extension StandardTorrentFile {
    var localizedProgress: String {
        L10n.File.progress(
            size: Formatters.bytes.string(fromByteCount: size),
            progress: Formatters.percentage.string(for: progress) ?? ""
        )
    }
}
