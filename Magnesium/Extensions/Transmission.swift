//
//  Transmission.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-18.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Transmission

typealias TransmissionError = Transmission.Client.Error
typealias DefaultTransmissionClient = Transmission.Client
typealias TransmissionTorrent = Transmission.Torrent

extension TransmissionTorrent: TorrentExt {
    var commonState: TorrentState {
        switch status {
        case .paused:
            return .paused
        case .checkQueued:
            return .queued
        case .checking:
            return .checking
        case .downloadQueued:
            return .queued
        case .downloading:
            return .downloading
        case .seedQueued:
            return .queued
        case .seeding:
            return .seeding
        case .isolated:
            return .error
        }
    }
}

extension TransmissionTorrent: FilterableTorrent {}
