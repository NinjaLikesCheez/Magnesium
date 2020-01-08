//
//  MockTorrentFile.swift
//  Magnesium
//
//  Created by James Hurst on 2019-12-30.
//  Copyright © 2019 James Hurst. All rights reserved.
//

import Foundation

struct MockTorrentFile: Hashable {
    var name: String
    var size: Int64
    var downloaded: Int64

    var progress: Float {
        return size != 0 ? Float(downloaded) / Float(size) : 0
    }
}
