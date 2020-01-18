//
//  DelugeTorrent.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-07.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Foundation

struct DelugeTorrent {
    let hash: String
    let name: String
    let state: TorrentState
    let dateAdded: Date
    let downloadRate: Int
    let uploadRate: Int
    let eta: TimeInterval
    let progress: Float
    let downloaded: Int64
    let uploaded: Int64
    let size: Int64
    let seeds: Int
    let totalSeeds: Int
    let peers: Int
    let totalPeers: Int
    let trackers: [String]
    let label: String
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
extension DelugeTorrent: SortableTorrent {}
