//
//  TorrentState+UI.swift
//  Magnesium
//
//  Created by James Hurst on 2019-12-18.
//  Copyright © 2019 James Hurst. All rights reserved.
//

import UIKit

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
