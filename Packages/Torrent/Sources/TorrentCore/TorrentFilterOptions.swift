public struct TorrentFilterOptions: Equatable, Codable {
	public var states: Set<StandardTorrentState> = []
	public var labels: Set<String> = []

	public init() {}
}
