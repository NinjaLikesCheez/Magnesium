//
//  TorrentExt.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-07.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Foundation

protocol TorrentExt {
    var state: TorrentState { get }
    var downloadRate: Int { get }
    var uploadRate: Int { get }
    var eta: TimeInterval { get }
    var size: Int64 { get }
    var downloaded: Int64 { get }
    var uploaded: Int64 { get }
}

extension TorrentExt {
    var ratio: Double {
        return Double(uploaded) / Double(downloaded)
    }

    var progress: Float {
        return size != 0 ? Float(downloaded) / Float(size) : 0
    }

    var speedString: String {
        if state == .downloading {
            return """
            ↓ \(ByteFormatter.string(fromByteCount: downloadRate))/s \
            ↑ \(ByteFormatter.string(fromByteCount: uploadRate))/s
            """
        } else if state == .seeding {
            return "↑ \(ByteFormatter.string(fromByteCount: uploadRate))/s"
        } else {
            return ""
        }
    }

    var progressString: String {
        return """
        \(ByteFormatter.string(fromByteCount: downloaded)) / \
        \(ByteFormatter.string(fromByteCount: size)) \
        (\(Int(progress * 100))%)
        """
    }

    var ratioOrETAString: String {
        if state == .downloading {
            return eta > 0
                ? DateFormatters.etaFormatter.string(from: eta) ?? ""
                : "∞"
        } else {
            return "Ratio: \(!ratio.isNaN ? String(format: "%.1f", ratio) : "∞")"
        }
    }
}
