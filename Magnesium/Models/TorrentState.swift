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
            return L10n.downloadingState
        case .seeding:
            return L10n.seedingState
        case .paused:
            return L10n.pausedState
        case .queued:
            return L10n.queuedState
        case .checking:
            return L10n.checkingState
        case .error:
            return L10n.errorState
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
