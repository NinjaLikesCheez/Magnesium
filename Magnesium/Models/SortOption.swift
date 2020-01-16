//
//  SortOption.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-07.
//  Copyright © 2020 James Hurst. All rights reserved.
//

struct SortOption: Equatable {
    enum Property: String, CaseIterable {
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

    enum Direction: String {
        case ascending
        case descending

        var displayString: String {
            switch self {
            case .ascending:
                return "Ascending"
            case .descending:
                return "Descending"
            }
        }
    }

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

    func withOppositeDirection() -> SortOption {
        let newDirection: Direction
        switch direction {
        case .ascending:
            newDirection = .descending
        case .descending:
            newDirection = .ascending
        }

        return SortOption(property: property, direction: newDirection)
    }
}
