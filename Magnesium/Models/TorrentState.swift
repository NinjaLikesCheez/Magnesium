//
//  TorrentState.swift
//  Magnesium
//
//  Created by James Hurst on 2019-11-11.
//  Copyright © 2019 James Hurst. All rights reserved.
//

import UIKit

enum TorrentState: String, Codable, Equatable, CaseIterable {
    case downloading
    case seeding
    case paused
    case checking
    case queued
    case error
}

extension TorrentState {
    var displayString: String {
        switch self {
        case .downloading:
            return "Downloading"
        case .seeding:
            return "Seeding"
        case .paused:
            return "Paused"
        case .queued:
            return "Queued"
        case .checking:
            return "Checking"
        case .error:
            return "Error"
        }
    }

    var displayColor: UIColor {
        switch self {
        case .seeding:
            return .systemGreen
        case .downloading:
            return .systemBlue
        case .error:
            return .systemRed
        case .queued, .checking:
            return .systemYellow
        case .paused:
            return .systemPurple
        }
    }
}
