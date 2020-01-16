//
//  TransmissionTorrent.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-14.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Foundation

struct TransmissionTorrent {
    private enum Status: Int {
        case paused = 0
        case checkQueued = 1
        case checking = 2
        case downloadQueued = 3
        case downloading = 4
        case seedQueued = 5
        case seeding = 6
        case isolated = 7

        var state: TorrentState {
            switch self {
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

    let id: Int
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
    let trackers: [TransmissionTracker]
}

extension TransmissionTorrent {
    init?(dictionary: [String: Any]) {
        guard let id = dictionary["id"] as? Int,
            let name = dictionary["name"] as? String,
            let statusCode = dictionary["status"] as? Int,
            let status = Status(rawValue: statusCode),
            let addedDate = dictionary["addedDate"] as? TimeInterval,
            let downloadRate = dictionary["rateDownload"] as? Int,
            let uploadRate = dictionary["rateUpload"] as? Int,
            let eta = dictionary["eta"] as? TimeInterval,
            let progress = dictionary["percentDone"] as? Double,
            let downloaded = dictionary["downloadedEver"] as? Int64,
            let uploaded = dictionary["uploadedEver"] as? Int64,
            let size = dictionary["totalSize"] as? Int64,
            let trackers = (dictionary["trackerStats"] as? [[String: Any]])?
            .compactMap({ TransmissionTracker(dictionary: $0) })
        else {
            return nil
        }

        self.id = id
        self.name = name
        state = status.state
        dateAdded = Date(timeIntervalSince1970: addedDate)
        self.downloadRate = downloadRate
        self.uploadRate = uploadRate
        self.eta = eta
        self.progress = Float(progress)
        self.downloaded = downloaded
        self.uploaded = uploaded
        self.size = size
        self.trackers = trackers
    }
}

extension TransmissionTorrent: TorrentExt {}
