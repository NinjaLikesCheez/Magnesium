struct SortOption {
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

extension SortOption: Codable {}
extension SortOption: Equatable {}

extension SortOption {
    enum Property: String {
        case dateAdded
        case name
        case downloadSpeed
        case uploadSpeed
    }
}

extension SortOption.Property {
    var preferredDirection: SortOption.Direction {
        switch self {
        case .name:
            return .ascending
        case .dateAdded, .downloadSpeed, .uploadSpeed:
            return .descending
        }
    }
}

extension SortOption.Property: CaseIterable {}
extension SortOption.Property: Codable {}
extension SortOption.Property: Equatable {}

extension SortOption {
    enum Direction: String {
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

extension SortOption.Direction: CaseIterable {}
extension SortOption.Direction: Codable {}
extension SortOption.Direction: Equatable {}

extension SortOption {
    var localizedString: String {
        let directionString: String
        switch direction {
        case .ascending:
            directionString = "↑"
        case .descending:
            directionString = "↓"
        }

        return "\(directionString) \(property.localizedString)"
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
        }
    }
}
