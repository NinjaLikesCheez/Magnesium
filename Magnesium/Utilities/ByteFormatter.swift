//
//  ByteFormatter.swift
//  Magnesium
//
//  Created by James Hurst on 2019-11-14.
//  Copyright © 2019 James Hurst. All rights reserved.
//


enum ByteFormatter {
    private static let unitSize = 1024

    static func string(fromByteCount byteCount: Int) -> String {
        if byteCount < unitSize * unitSize {
            return String(format: "%.1f KB", Double(byteCount) / Double(unitSize))
        } else if byteCount < unitSize * unitSize * unitSize {
            return String(format: "%.1f MB", Double(byteCount) / Double(unitSize * unitSize))
        } else if byteCount < unitSize * unitSize * unitSize * unitSize {
            return String(format: "%.1f GB", Double(byteCount) / Double(unitSize * unitSize * unitSize))
        } else {
            return String(format: "%.1f TB", Double(byteCount) / Double(unitSize * unitSize * unitSize * unitSize))
        }
    }

    static func string(fromByteCount byteCount: Int64) -> String {
        return string(fromByteCount: Int(byteCount))
    }
}
