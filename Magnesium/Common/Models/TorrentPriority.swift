enum TorrentPriority {
    case disabled
    case low
    case normal
    case high
}

extension TorrentPriority: Equatable {}
extension TorrentPriority: Hashable {}
