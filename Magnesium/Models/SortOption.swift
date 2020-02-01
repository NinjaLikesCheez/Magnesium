//
//  SortOption.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-07.
//  Copyright © 2020 James Hurst. All rights reserved.
//

struct SortOption: Codable {
    var property: Property
    var direction: Direction

    var displayString: String {
        let directionString: String
        switch direction {
        case .ascending:
            directionString = "↑"
        case .descending:
            directionString = "↓ "
        }

        return "\(directionString) \(property.displayString)"
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
    enum Property: String, Codable, CaseIterable {
        case name
        case dateAdded
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

        var displayString: String {
            switch self {
            case .name:
                return "Name"
            case .dateAdded:
                return "Date Added"
            case .downloadSpeed:
                return "Download Speed"
            case .uploadSpeed:
                return "Upload Speed"
            }
        }
    }
}

extension SortOption {
    enum Direction: String, Codable {
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
