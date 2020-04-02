struct TorrentDetailSection {
    let type: TorrentDetailSectionType
    let items: [TorrentDetailItem]
}

extension TorrentDetailSection: Equatable {}
