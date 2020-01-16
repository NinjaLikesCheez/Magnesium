//
//  TorrentDetailSection.swift
//  Magnesium
//
//  Created by James Hurst on 2019-12-25.
//  Copyright © 2019 James Hurst. All rights reserved.
//

struct TorrentDetailSection: Equatable {
    let type: TorrentDetailSectionType
    let items: [TorrentDetailItem]
}

enum TorrentDetailSectionType: Equatable {
    case header
    case info
    case trackers
    case files
}

extension TorrentDetailSectionType {
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
