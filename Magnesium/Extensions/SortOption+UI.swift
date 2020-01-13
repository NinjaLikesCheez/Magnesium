//
//  SortOption+UI.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-08.
//  Copyright © 2020 James Hurst. All rights reserved.
//

extension SortOption.Property {
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

extension SortOption.Direction {
    var displayString: String {
        switch self {
        case .ascending:
            return "Ascending"
        case .descending:
            return "Descending"
        }
    }
}
