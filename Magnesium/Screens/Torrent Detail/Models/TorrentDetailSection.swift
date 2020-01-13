//
//  TorrentDetailSection.swift
//  Magnesium
//
//  Created by James Hurst on 2019-12-25.
//  Copyright © 2019 James Hurst. All rights reserved.
//

enum TorrentDetailSection {
    case header
    case info
    case trackers
    case files
}

extension TorrentDetailSection {
    var displayString: String? {
        switch self {
        case .header:
            return nil
        case .info:
            return "Information"
        case .trackers:
            return "Trackers"
        case .files:
            return "Files"
        }
    }
}
