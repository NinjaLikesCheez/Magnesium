//
//  SortOption.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-07.
//  Copyright © 2020 James Hurst. All rights reserved.
//

struct SortOption: Codable, Equatable {
    var property: Property
    var direction: Direction

    var displayString: String {
        let directionString: String
        switch direction {
        case .ascending:
            directionString = "↑"
        case .descending:
            directionString = "↓"
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

        var displayString: String {
            switch self {
            case .dateAdded:
                return "Date Added"
            case .name:
                return "Name"
            case .downloadSpeed:
                return "Download Speed"
            case .uploadSpeed:
                return "Upload Speed"
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
