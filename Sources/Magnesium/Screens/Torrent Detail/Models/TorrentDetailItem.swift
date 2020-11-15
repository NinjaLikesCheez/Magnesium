enum TorrentDetailItem: Equatable, Hashable {
    case header(TorrentDetailHeaderItem)
    case info(TorrentDetailInfoItem)
    case tracker(String)
    case file(TorrentDetailFileItem)
}
