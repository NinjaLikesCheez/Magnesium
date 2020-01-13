//
//  DelugeTorrent.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-07.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Foundation

struct DelugeTorrent: Equatable {
    let hash: String
    var name: String
    var state: TorrentState
    var dateAdded: Date
    var downloadRate: Int
    var uploadRate: Int
    var eta: TimeInterval
    var progress: Float
    var downloaded: Int64
    var uploaded: Int64
    var size: Int64
    var seeds: Int
    var totalSeeds: Int
    var peers: Int
    var totalPeers: Int
    var trackers: [String]
    var label: String
}

extension DelugeTorrent {
    init?(hash: String, dictionary: [String: Any]) {
        guard let name = dictionary["name"] as? String,
            let stateString = dictionary["state"] as? String,
            let timeAdded = dictionary["time_added"] as? TimeInterval,
            let downloadRate = dictionary["download_payload_rate"] as? Int,
            let uploadRate = dictionary["upload_payload_rate"] as? Int,
            let eta = dictionary["eta"] as? TimeInterval,
            let progress = dictionary["progress"] as? Float,
            let downloaded = dictionary["total_done"] as? Int64,
            let uploaded = dictionary["total_uploaded"] as? Int64,
            let size = dictionary["total_size"] as? Int64,
            let seeds = dictionary["num_seeds"] as? Int,
            let totalSeeds = dictionary["total_seeds"] as? Int,
            let peers = dictionary["num_peers"] as? Int,
            let totalPeers = dictionary["total_peers"] as? Int,
            let trackers = (dictionary["trackers"] as? [[String: Any]])?.compactMap({ $0["url"] as? String }),
            let label = dictionary["label"] as? String
        else {
            return nil
        }

        switch stateString {
        case "Downloading":
            state = .downloading
        case "Seeding":
            state = .seeding
        case "Paused":
            state = .paused
        case "Checking":
            state = .checking
        case "Queued":
            state = .queued
        case "Error":
            state = .error
        default:
            return nil
        }

        self.hash = hash
        self.name = name
        dateAdded = Date(timeIntervalSince1970: timeAdded)
        self.downloadRate = downloadRate
        self.uploadRate = uploadRate
        self.eta = eta
        self.progress = progress / 100
        self.downloaded = downloaded
        self.uploaded = uploaded
        self.size = size
        self.seeds = seeds
        self.totalSeeds = totalSeeds
        self.peers = peers
        self.totalPeers = totalPeers
        self.trackers = trackers
        self.label = label
    }
}

extension DelugeTorrent: TorrentExt {}
