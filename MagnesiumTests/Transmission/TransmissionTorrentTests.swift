//
//  TransmissionTorrentTests.swift
//  MagnesiumTests
//
//  Created by James Hurst on 2020-02-02.
//  Copyright © 2020 James Hurst. All rights reserved.
//

@testable import Magnesium
import XCTest

class TransmissionTorrentTests: XCTestCase {
    func test_standardState() {
        let pairs: [(TransmissionTorrent.Status, TorrentState)] = [
            (.downloading, .downloading),
            (.seeding, .seeding),
            (.paused, .paused),
            (.checking, .checking),
            (.checkQueued, .queued),
            (.downloadQueued, .queued),
            (.seedQueued, .queued),
            (.isolated, .error),
        ]

        for pair in pairs {
            let torrent = TransmissionTorrent.mock(status: pair.0)
            XCTAssertEqual(torrent.standardState, pair.1)
        }
    }
}
