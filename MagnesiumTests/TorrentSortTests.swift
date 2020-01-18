//
//  TorrentSortTests.swift
//  MagnesiumTests
//
//  Created by James Hurst on 2020-01-18.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import CryptoKit
@testable import Magnesium
import XCTest

class TorrentSortTests: XCTestCase {
    func testSortByName() {
        let torrents = [
            MockTorrent(name: "B", dateAdded: Date(), downloadRate: 0, uploadRate: 0),
            MockTorrent(name: "A", dateAdded: Date(), downloadRate: 0, uploadRate: 0),
            MockTorrent(name: "a", dateAdded: Date(), downloadRate: 0, uploadRate: 0),
            MockTorrent(name: "C", dateAdded: Date(), downloadRate: 0, uploadRate: 0),
        ]
        let subjects = torrents.map { CurrentValueSubject<MockTorrent, Never>($0) }
        let expectedAscending: [String] = [torrents[1].hash, torrents[2].hash].sorted()
            + [torrents[0].hash, torrents[3].hash]
        let expectedDescending: [String] = [torrents[3].hash, torrents[0].hash]
            + [torrents[1].hash, torrents[2].hash].sorted()

        let sortedAscendingSubjects = TorrentSortUtil.sort(
            subjects,
            using: SortOption(property: .name, direction: .ascending)
        )
        let sortedAscending = sortedAscendingSubjects.map { $0.value.hash }
        XCTAssertEqual(sortedAscending, expectedAscending)

        let sortedDescendingSubjects = TorrentSortUtil.sort(
            subjects,
            using: SortOption(property: .name, direction: .descending)
        )
        let sortedDescending = sortedDescendingSubjects.map { $0.value.hash }
        XCTAssertEqual(sortedDescending, expectedDescending)
    }

    func testSortByDateAdded() {
        let date = Date()
        let torrents = [
            MockTorrent(name: "B", dateAdded: date.addingTimeInterval(1), downloadRate: 0, uploadRate: 0),
            MockTorrent(name: "A1", dateAdded: date, downloadRate: 0, uploadRate: 0),
            MockTorrent(name: "a2", dateAdded: date, downloadRate: 0, uploadRate: 0),
            MockTorrent(name: "A1", dateAdded: date, downloadRate: 0, uploadRate: 0),
            MockTorrent(name: "C", dateAdded: date.addingTimeInterval(2), downloadRate: 0, uploadRate: 0),
        ]
        let subjects = torrents.map { CurrentValueSubject<MockTorrent, Never>($0) }
        let expectedAscending = [torrents[1].hash, torrents[3].hash].sorted()
            + [torrents[2].hash, torrents[0].hash, torrents[4].hash]
        let expectedDescending = [torrents[4].hash, torrents[0].hash]
            + [torrents[1].hash, torrents[3].hash].sorted()
            + [torrents[2].hash]

        let sortedAscendingSubjects = TorrentSortUtil.sort(
            subjects,
            using: SortOption(property: .dateAdded, direction: .ascending)
        )
        let sortedAscending = sortedAscendingSubjects.map { $0.value.hash }
        XCTAssertEqual(sortedAscending, expectedAscending)

        let sortedDescendingSubjects = TorrentSortUtil.sort(
            subjects,
            using: SortOption(property: .dateAdded, direction: .descending)
        )
        let sortedDescending = sortedDescendingSubjects.map { $0.value.hash }
        XCTAssertEqual(sortedDescending, expectedDescending)
    }

    func testSortByDownloadSpeed() {
        let torrents = [
            MockTorrent(name: "B", dateAdded: Date(), downloadRate: 1, uploadRate: 0),
            MockTorrent(name: "A1", dateAdded: Date(), downloadRate: 0, uploadRate: 0),
            MockTorrent(name: "a2", dateAdded: Date(), downloadRate: 0, uploadRate: 0),
            MockTorrent(name: "A1", dateAdded: Date(), downloadRate: 0, uploadRate: 0),
            MockTorrent(name: "C", dateAdded: Date(), downloadRate: 2, uploadRate: 0),
        ]
        let subjects = torrents.map { CurrentValueSubject<MockTorrent, Never>($0) }
        let expectedAscending = [torrents[1].hash, torrents[3].hash].sorted()
            + [torrents[2].hash, torrents[0].hash, torrents[4].hash]
        let expectedDescending = [torrents[4].hash, torrents[0].hash]
            + [torrents[1].hash, torrents[3].hash].sorted()
            + [torrents[2].hash]

        let sortedAscendingSubjects = TorrentSortUtil.sort(
            subjects,
            using: SortOption(property: .downloadSpeed, direction: .ascending)
        )
        let sortedAscending = sortedAscendingSubjects.map { $0.value.hash }
        XCTAssertEqual(sortedAscending, expectedAscending)

        let sortedDescendingSubjects = TorrentSortUtil.sort(
            subjects,
            using: SortOption(property: .downloadSpeed, direction: .descending)
        )
        let sortedDescending = sortedDescendingSubjects.map { $0.value.hash }
        XCTAssertEqual(sortedDescending, expectedDescending)
    }

    func testSortByUploadSpeed() {
        let torrents = [
            MockTorrent(name: "B", dateAdded: Date(), downloadRate: 0, uploadRate: 1),
            MockTorrent(name: "A1", dateAdded: Date(), downloadRate: 0, uploadRate: 0),
            MockTorrent(name: "a2", dateAdded: Date(), downloadRate: 0, uploadRate: 0),
            MockTorrent(name: "A1", dateAdded: Date(), downloadRate: 0, uploadRate: 0),
            MockTorrent(name: "C", dateAdded: Date(), downloadRate: 0, uploadRate: 2),
        ]
        let subjects = torrents.map { CurrentValueSubject<MockTorrent, Never>($0) }
        let expectedAscending = [torrents[1].hash, torrents[3].hash].sorted()
            + [torrents[2].hash, torrents[0].hash, torrents[4].hash]
        let expectedDescending = [torrents[4].hash, torrents[0].hash]
            + [torrents[1].hash, torrents[3].hash].sorted()
            + [torrents[2].hash]

        let sortedAscendingSubjects = TorrentSortUtil.sort(
            subjects,
            using: SortOption(property: .uploadSpeed, direction: .ascending)
        )
        let sortedAscending = sortedAscendingSubjects.map { $0.value.hash }
        XCTAssertEqual(sortedAscending, expectedAscending)

        let sortedDescendingSubjects = TorrentSortUtil.sort(
            subjects,
            using: SortOption(property: .uploadSpeed, direction: .descending)
        )
        let sortedDescending = sortedDescendingSubjects.map { $0.value.hash }
        XCTAssertEqual(sortedDescending, expectedDescending)
    }
}

private struct MockTorrent: SortableTorrent {
    let hash: String = {
        let data = UUID().uuidString.data(using: .utf8)!
        let hashed = Insecure.SHA1.hash(data: data)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }()

    let name: String
    let dateAdded: Date
    let downloadRate: Int64
    let uploadRate: Int64
}
