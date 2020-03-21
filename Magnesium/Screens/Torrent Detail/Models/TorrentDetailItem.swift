enum TorrentDetailItem {
    case header(TorrentDetailHeaderItem)
    case info(TorrentDetailInfoItem)
    case tracker(String)
    case file(TorrentDetailFileItem)
}

extension TorrentDetailItem: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case let (.header(value1), .header(value2)):
            return value1.id == value2.id
        case let (.info(value1), .info(value2)):
            return value1.id == value2.id
        case let (.tracker(value1), .tracker(value2)):
            return value1 == value2
        case let (.file(value1), .file(value2)):
            return value1.id == value2.id
        default:
            return false
        }
    }
}

extension TorrentDetailItem: Hashable {
    func hash(into hasher: inout Hasher) {
        switch self {
        case let .header(value):
            hasher.combine(value.id)
        case let .info(value):
            hasher.combine(value.id)
        case let .tracker(value):
            hasher.combine(value)
        case let .file(value):
            hasher.combine(value.id)
        }
    }
}
