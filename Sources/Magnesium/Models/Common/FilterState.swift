struct FilterOptions: Equatable, Codable {
	var states: Set<TorrentState> = []
	var labels: Set<String> = []
}
