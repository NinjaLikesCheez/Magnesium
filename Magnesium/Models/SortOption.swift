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
        var string = ""

        switch direction {
        case .ascending:
            string += "↑ "
        case .descending:
            string += "↓ "
        }

        switch property {
        case .name:
            string += "Name"
        case .dateAdded:
            string += "Date Added"
        case .downloadSpeed:
            string += "Download Speed"
        case .uploadSpeed:
            string += "Upload Speed"
        }

        return string
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
    }
}

extension SortOption {
    enum Direction: String, Codable {
        case ascending
        case descending
    }
}
