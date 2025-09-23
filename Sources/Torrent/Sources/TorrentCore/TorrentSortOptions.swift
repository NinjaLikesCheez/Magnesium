public struct TorrentSortOption: Equatable, Hashable, Codable {
	public var property: Property
	public var direction: Direction

	public init(property: Property) {
		self.property = property
		direction = property.preferredDirection
	}

	public init(property: Property, direction: Direction) {
		self.property = property
		self.direction = direction
	}
}

public extension TorrentSortOption {
	func withOppositeDirection() -> TorrentSortOption {
		var torrentSortOption = self
		torrentSortOption.direction = torrentSortOption.direction.opposite
		return torrentSortOption
	}
}

public extension TorrentSortOption {
	enum Property: String, Equatable, Hashable, Codable, CaseIterable {
		case dateAdded = "Date Added"
		case name = "Name"
		case downloadSpeed = "Download Speed"
		case uploadSpeed = "Upload Speed"
		case progress = "Progress"
	}
}

public extension TorrentSortOption.Property {
	var preferredDirection: TorrentSortOption.Direction {
		switch self {
		case .name:
			.ascending
		case .dateAdded, .downloadSpeed, .uploadSpeed, .progress:
			.descending
		}
	}
}

public extension TorrentSortOption {
	enum Direction: String, Equatable, Hashable, Codable, CaseIterable {
		case ascending = "Ascending"
		case descending = "Descending"
	}
}

public extension TorrentSortOption.Direction {
	var opposite: TorrentSortOption.Direction {
		switch self {
		case .ascending:
			.descending
		case .descending:
			.ascending
		}
	}
}

public extension TorrentSortOption {
	var localizedString: String {
		switch direction {
		case .ascending:
			"↑ \(property.localizedString)"
		case .descending:
			"↓ \(property.localizedString)"
		}
	}
}

extension TorrentSortOption.Property {
	var localizedString: String {
		switch self {
		case .dateAdded:
			"Date Added"
		case .name:
			"Name"
		case .downloadSpeed:
			"Download Speed"
		case .uploadSpeed:
			"Upload Speed"
		case .progress:
			"Progress"
		}
	}
}
