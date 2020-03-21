enum TorrentDetailSectionType {
    case header
    case info
    case trackers
    case files
}

extension TorrentDetailSectionType: Equatable {}
extension TorrentDetailSectionType: Hashable {}
