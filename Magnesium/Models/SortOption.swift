import Foundation

struct SortOption: Codable, Equatable {
    var property: Property
    var direction: Direction

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

    init(property: Property) {
        self.property = property
        direction = property.preferredDirection
    }

    init(property: Property, direction: Direction) {
        self.property = property
        self.direction = direction
    }

    func withOppositeDirection() -> SortOption {
        var sortOption = self
        sortOption.direction = sortOption.direction.opposite
        return sortOption
    }
}

extension SortOption {
    enum Property: String, Codable, Equatable, CaseIterable {
        case dateAdded
        case name
        case downloadSpeed
        case uploadSpeed

        var preferredDirection: Direction {
            switch self {
            case .name:
                return .ascending
            case .dateAdded, .downloadSpeed, .uploadSpeed:
                return .descending
            }
        }

        var localizedString: String {
            switch self {
            case .dateAdded:
                return L10n.sortPropertyDateAdded
            case .name:
                return L10n.sortPropertyName
            case .downloadSpeed:
                return L10n.sortPropertyDownloadSpeed
            case .uploadSpeed:
                return L10n.sortPropertyUploadSpeed
            }
        }
    }
}

extension SortOption {
    enum Direction: String, Codable, Equatable {
        case ascending
        case descending

        var opposite: Direction {
            switch self {
            case .ascending:
                return .descending
            case .descending:
                return .ascending
            }
        }
    }
}
