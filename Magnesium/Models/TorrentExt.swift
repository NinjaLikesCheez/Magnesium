//
//  TorrentExt.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-07.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Foundation

protocol TorrentExt {
    var commonState: TorrentState { get }
    var downloadRate: Int64 { get }
    var uploadRate: Int64 { get }
    var eta: TimeInterval { get }
    var progress: Float { get }
    var size: Int64 { get }
    var downloaded: Int64 { get }
    var uploaded: Int64 { get }
}

extension TorrentExt {
    var ratio: Double {
        return Double(uploaded) / Double(downloaded)
    }

    var isActive: Bool {
        return commonState == .downloading || commonState == .seeding
    }

    var speedString: String {
        if commonState == .downloading {
            return """
            ↓ \(ByteFormatter.string(fromByteCount: downloadRate))/s \
            ↑ \(ByteFormatter.string(fromByteCount: uploadRate))/s
            """
        } else if commonState == .seeding {
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
        if commonState == .downloading {
            return eta > 0
                ? DateFormatters.etaFormatter.string(from: eta) ?? ""
                : "∞"
        } else {
            return "Ratio: \(!ratio.isInfinite ? String(format: "%.1f", ratio) : "∞")"
        }
    }
}
