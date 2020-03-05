//
//  DelugeTorrent.swift
//  Magnesium
//
//  Created by James Hurst on 2020-03-01.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Deluge
import Foundation

struct DelugeTorrent: StandardTorrent {
    /// The torrent's hash.
    var hash: String
    /// The torrent's name.
    var name: String
    /// The torrent's current state.
    var standardState: TorrentState
    /// The date the torrent was added to the server.
    var dateAdded: Date
    /// The torrent's current download rate in bytes/s.
    var downloadRate: Int64
    /// The torrent's current upload rate in bytes/s.
    var uploadRate: Int64
    /// The torrent's current ETA.
    var eta: TimeInterval
    /// The torrent's current progress. This is a value between 0 and 1.
    var progress: Float
    /// The amount of data currently downloaded for the torrent in bytes.
    var downloaded: Int64
    /// The amount of data currently uploaded for the torrent in bytes.
    var uploaded: Int64
    /// The size of the torrent in bytes.
    var size: Int64
    /// The number of connected seeds.
    var seeds: Int
    /// The total number of seeds.
    var totalSeeds: Int
    /// The number of connected peers.
    var peers: Int
    /// The total number of peers.
    var totalPeers: Int
    /// The torrent's tracker URLs.
    var trackerStrings: [String]
    /// The torrent's label.
    var label: String
    /// The torrent's download path.
    var downloadPath: String

    /// Creates a `DelugeTorrent` from a `Deluge.Torrent`, returning nil if any required properties are missing.
    /// - Parameter torrent: The `Deluge.Torrent` to create a `DelugeTorrent` from.
    init?(_ torrent: Deluge.Torrent) {
        guard let name = torrent.name,
            let state = torrent.state,
            let dateAdded = torrent.dateAdded,
            let downloadRate = torrent.downloadRate,
            let uploadRate = torrent.uploadRate,
            let eta = torrent.eta,
            let progress = torrent.progress,
            let downloaded = torrent.downloaded,
            let uploaded = torrent.uploaded,
            let size = torrent.size,
            let seeds = torrent.seeds,
            let totalSeeds = torrent.totalSeeds,
            let peers = torrent.peers,
            let totalPeers = torrent.totalPeers,
            let trackers = torrent.trackers,
            let label = torrent.label,
            let downloadPath = torrent.downloadPath
        else {
            return nil
        }

        hash = torrent.hash
        self.name = name
        standardState = {
            switch state {
            case .downloading:
                return .downloading
            case .seeding:
                return .seeding
            case .paused:
                return .paused
            case .checking:
                return .checking
            case .queued:
                return .queued
            case .error:
                return .error
            }
        }()
        self.dateAdded = dateAdded
        self.downloadRate = downloadRate
        self.uploadRate = uploadRate
        self.eta = eta
        self.progress = progress
        self.downloaded = downloaded
        self.uploaded = uploaded
        self.size = size
        self.seeds = seeds
        self.totalSeeds = totalSeeds
        self.peers = peers
        self.totalPeers = totalPeers
        trackerStrings = trackers.map { $0.url }
        self.label = label
        self.downloadPath = downloadPath
    }
}
