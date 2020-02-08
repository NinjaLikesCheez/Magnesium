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

    var speedString: String {
        if standardState == .downloading {
            return """
            ↓ \(ByteFormatter.string(fromByteCount: downloadRate))/s \
            ↑ \(ByteFormatter.string(fromByteCount: uploadRate))/s
            """
        } else if standardState == .seeding {
            return "↑ \(ByteFormatter.string(fromByteCount: uploadRate))/s"
        } else {
            return ""
        }
    }

    var progressString: String {
        return """
        \(ByteFormatter.string(fromByteCount: downloaded)) / \
        \(ByteFormatter.string(fromByteCount: size)) \
        (\(String(format: "%.0f", progress * 100))%)
        """
    }

    var etaString: String {
        return eta > 0 ? DateFormatters.etaFormatter.string(from: eta) ?? "" : "∞"
    }

    func ratioString(precision: Int = 1) -> String {
        return !ratio.isInfinite && !ratio.isNaN ? String(format: "%.\(precision)f", ratio) : "∞"
    }

    var ratioOrETAString: String {
        if standardState == .downloading {
            return etaString
        } else {
            return "Ratio: \(ratioString())"
        }
    }
}
