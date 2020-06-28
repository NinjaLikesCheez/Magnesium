struct FilterOptions {
    var state: TorrentState?
    var label: String?
}

extension FilterOptions: Codable {}
extension FilterOptions: Equatable {}
