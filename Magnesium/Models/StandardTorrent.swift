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

    var formattedSpeed: String {
        if standardState == .downloading {
            let downloadFormat = NSLocalizedString("torrent_download_speed", comment: "↓ {bytes}/s")
            let download = String.localizedStringWithFormat(
                downloadFormat,
                Formatters.bytes.string(fromByteCount: downloadRate)
            )
            let uploadFormat = NSLocalizedString("torrent_upload_speed", comment: "↑ {bytes}/s")
            let upload = String.localizedStringWithFormat(
                uploadFormat,
                Formatters.bytes.string(fromByteCount: uploadRate)
            )
            return "\(download) \(upload)"
        } else if standardState == .seeding {
            let format = NSLocalizedString("torrent_upload_speed", comment: "↑ {bytes}/s")
            return .localizedStringWithFormat(format, Formatters.bytes.string(fromByteCount: uploadRate))
        } else {
            return ""
        }
    }

    var formattedLongProgress: String {
        let format = NSLocalizedString("torrent_progress", comment: "{downloaded} / {uploaded} ({percentage})")
        return .localizedStringWithFormat(
            format,
            Formatters.bytes.string(fromByteCount: downloaded),
            Formatters.bytes.string(fromByteCount: size),
            Formatters.percentage.string(for: progress) ?? ""
        )
    }

    var formattedETA: String {
        return eta > 0 ? Formatters.eta.string(from: eta) ?? "" : "∞"
    }

    func formattedRatio(precision: Int = 1) -> String {
        guard !ratio.isInfinite, !ratio.isNaN else { return "∞" }
        return Formatters.number(precision: precision).string(for: ratio) ?? ""
    }

    var formattedRatioOrETA: String {
        if standardState == .downloading {
            return formattedETA
        } else {
            let format = NSLocalizedString("torrent_ratio", comment: "Ratio: {number}")
            return .localizedStringWithFormat(format, formattedRatio())
        }
    }
}
