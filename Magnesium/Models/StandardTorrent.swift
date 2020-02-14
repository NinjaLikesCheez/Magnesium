//
//  StandardTorrent.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-07.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Foundation

protocol StandardTorrent {
    var hash: String { get }
    var name: String { get }
    var standardState: TorrentState { get }
    var dateAdded: Date { get }
    var downloadRate: Int64 { get }
    var uploadRate: Int64 { get }
    var eta: TimeInterval { get }
    var progress: Float { get }
    var downloaded: Int64 { get }
    var uploaded: Int64 { get }
    var size: Int64 { get }
    var seeds: Int { get }
    var totalSeeds: Int { get }
    var peers: Int { get }
    var totalPeers: Int { get }
    var trackerStrings: [String] { get }
    var label: String { get }
}

extension StandardTorrent {
    var ratio: Double {
        return Double(uploaded) / Double(downloaded)
    }

    var isActive: Bool {
        return standardState == .downloading || standardState == .seeding
    }

    var localizedSpeed: String {
        if standardState == .downloading {
            let download = L10n.torrentDownloadSpeed(Formatters.bytes.string(fromByteCount: downloadRate))
            let upload = L10n.torrentUploadSpeed(Formatters.bytes.string(fromByteCount: uploadRate))
            return "\(download) \(upload)"
        } else if standardState == .seeding {
            return L10n.torrentUploadSpeed(Formatters.bytes.string(fromByteCount: uploadRate))
        } else {
            return ""
        }
    }

    var localizedProgress: String {
        return L10n.torrentProgress(
            downloaded: Formatters.bytes.string(fromByteCount: downloaded),
            size: Formatters.bytes.string(fromByteCount: size),
            progress: Formatters.percentage.string(for: progress) ?? ""
        )
    }

    var formattedETA: String {
        return eta > 0 ? Formatters.eta.string(from: eta) ?? "" : "∞"
    }

    func formattedRatio(precision: Int = 1) -> String {
        guard !ratio.isInfinite, !ratio.isNaN else { return "∞" }
        return Formatters.number(precision: precision).string(for: ratio) ?? ""
    }

    var localizedRatioOrETA: String {
        if standardState == .downloading {
            return formattedETA
        } else {
            return L10n.torrentRatio(formattedRatio())
        }
    }
}
