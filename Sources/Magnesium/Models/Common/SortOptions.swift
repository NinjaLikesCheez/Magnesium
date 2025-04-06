struct SortOption: Equatable, Codable {
	var property: Property
	var direction: Direction

	init(property: Property) {
		self.property = property
		direction = property.preferredDirection
	}

	init(property: Property, direction: Direction) {
		self.property = property
		self.direction = direction
	}
}

extension SortOption {
	func withOppositeDirection() -> SortOption {
		var sortOption = self
		sortOption.direction = sortOption.direction.opposite
		return sortOption
	}
}

extension SortOption {
	enum Property: String, Equatable, Codable, CaseIterable {
		case dateAdded
		case name
		case downloadSpeed
		case uploadSpeed
		case progress
	}
}

extension SortOption.Property {
	var preferredDirection: SortOption.Direction {
		switch self {
		case .name:
			return .ascending
		case .dateAdded, .downloadSpeed, .uploadSpeed, .progress:
			return .descending
		}
	}
}

extension SortOption {
	enum Direction: String, Equatable, Codable, CaseIterable {
		case ascending
		case descending
	}
}

extension SortOption.Direction {
	var opposite: SortOption.Direction {
		switch self {
		case .ascending:
			return .descending
		case .descending:
			return .ascending
		}
	}
}

extension SortOption {
	var localizedString: String {
		switch direction {
		case .ascending:
			return L10n.Sort.ascending(property: property.localizedString)
		case .descending:
			return L10n.Sort.descending(property: property.localizedString)
		}
	}
}

extension SortOption.Property {
	var localizedString: String {
		switch self {
		case .dateAdded:
			return L10n.Sort.dateAdded
		case .name:
			return L10n.Sort.name
		case .downloadSpeed:
			return L10n.Sort.downloadSpeed
		case .uploadSpeed:
			return L10n.Sort.uploadSpeed
		case .progress:
			return L10n.Sort.progress
		}
	}
}
