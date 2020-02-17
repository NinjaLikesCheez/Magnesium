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
    func test_standardState() {
        let pairs: [(DelugeTorrent.State, TorrentState)] = [
            (.downloading, .downloading),
            (.seeding, .seeding),
            (.paused, .paused),
            (.checking, .checking),
            (.queued, .queued),
            (.error, .error),
        ]

        for pair in pairs {
            let torrent = DelugeTorrent.mock(state: pair.0)
            XCTAssertEqual(torrent.standardState, pair.1)
        }
    }

    func test_trackerStrings_shouldBeEqualToTrackers() {
        let trackers = ["udp://tracker.example.com:9000", "http://tracker.example.com:9000/announce"]
        XCTAssertEqual(DelugeTorrent.mock(trackers: trackers).trackerStrings, trackers)
    }
}
