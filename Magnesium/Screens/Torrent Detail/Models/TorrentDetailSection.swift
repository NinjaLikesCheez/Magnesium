struct TorrentDetailSection: Equatable {
    enum SectionType: Equatable {
        case header
        case info
        case trackers
        case files
    }

    let type: SectionType
    let items: [TorrentDetailItem]
}
