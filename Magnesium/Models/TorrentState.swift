//
//  TorrentState.swift
//  Magnesium
//
//  Created by James Hurst on 2019-11-11.
//  Copyright © 2019 James Hurst. All rights reserved.
//

import Foundation

enum TorrentState: Equatable, CaseIterable {
    case downloading
    case seeding
    case paused
    case checking
    case queued
    case error
}
