import Foundation

/// A protocol-agnostic view of a Sonarr series, decoupled from `sonarr-swift`'s `SeriesResource`.
public struct StandardSeries: Sendable, Equatable, Hashable, Identifiable {
	public var id: Int
	public var title: String
	public var overview: String?
	public var seasonCount: Int
	public var episodeCount: Int
	public var episodeFileCount: Int
	public var monitored: Bool

	public init(
		id: Int,
		title: String,
		overview: String? = nil,
		seasonCount: Int,
		episodeCount: Int,
		episodeFileCount: Int,
		monitored: Bool
	) {
		self.id = id
		self.title = title
		self.overview = overview
		self.seasonCount = seasonCount
		self.episodeCount = episodeCount
		self.episodeFileCount = episodeFileCount
		self.monitored = monitored
	}
}
