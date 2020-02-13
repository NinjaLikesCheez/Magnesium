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
    var localizedString: String {
        switch self {
        case .downloading:
            return NSLocalizedString("torrent_state_downloading", comment: "Downloading")
        case .seeding:
            return NSLocalizedString("torrent_state_seeding", comment: "Seeding")
        case .paused:
            return NSLocalizedString("torrent_state_paused", comment: "Paused")
        case .queued:
            return NSLocalizedString("torrent_state_queued", comment: "Queued")
        case .checking:
            return NSLocalizedString("torrent_state_checking", comment: "Checking")
        case .error:
            return NSLocalizedString("torrent_state_error", comment: "Error")
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
