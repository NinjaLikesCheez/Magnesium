//
//  MockTorrentFile.swift
//  MagnesiumTests
//
//  Created by James Hurst on 2020-02-16.
//  Copyright © 2020 James Hurst. All rights reserved.
//

@testable import Magnesium

struct MockTorrentFile: StandardTorrentFile {
    var index: Int = 0
    var name: String = ""
    var size: Int64 = 0
    var progress: Float = 0
}
