//
//  DelugeTorrentTests.swift
//  MagnesiumTests
//
//  Created by James Hurst on 2020-01-20.
//  Copyright © 2020 James Hurst. All rights reserved.
//

@testable import Magnesium
import XCTest

class DelugeTorrentTests: XCTestCase {
    func test_commonState() {
        let pairs: [(DelugeTorrent.State, TorrentState)] = [
            (.downloading, .downloading),
            (.seeding, .seeding),
            (.paused, .paused),
            (.checking, .checking),
            (.queued, .queued),
            (.error, .error),
        ]

        for pair in pairs {
            var torrent = DelugeTorrent.mock()
            torrent.state = pair.0
            XCTAssertEqual(torrent.commonState, pair.1)
        }
    }
}
