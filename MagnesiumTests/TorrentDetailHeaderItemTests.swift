//
//  TorrentDetailHeaderItemTests.swift
//  MagnesiumTests
//
//  Created by James Hurst on 2020-01-26.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
@testable import Magnesium
import XCTest

class TorrentDetailHeaderItemTests: XCTestCase {
    private var torrent: CurrentValueSubject<MockTorrent, Never>!
    private var item: TorrentDetailHeaderItem!
    private var observers = [AnyCancellable]()

    override func setUp() {
        super.setUp()
        torrent = CurrentValueSubject(MockTorrent())
        item = TorrentDetailHeaderItem(torrent: torrent)
    }

    func test_name() {
        torrent.send(MockTorrent(name: "name"))
        var name: String?
        item.name.sink { name = $0 }.store(in: &observers)
        XCTAssertEqual(name, "name")
    }

    func test_label() {
        torrent.send(MockTorrent(label: "label"))
        var label: String?
        item.label.sink { label = $0 }.store(in: &observers)
        XCTAssertEqual(label, "label")
    }

    func test_isActive_withActiveStates_shouldBeTrue() {
        for state in [TorrentState.downloading, .seeding] {
            torrent.send(MockTorrent(standardState: state))
            var isActive: Bool?
            item.isActive.sink { isActive = $0 }.store(in: &observers)
            XCTAssertEqual(isActive, true) // swiftlint:disable:this xct_specific_matcher
        }
    }

    func test_isActive_withInactiveState_shouldBeFalse() {
        for state in [TorrentState.paused, .checking, .queued, .error] {
            torrent.send(MockTorrent(standardState: state))
            var isActive: Bool?
            item.isActive.sink { isActive = $0 }.store(in: &observers)
            XCTAssertEqual(isActive, false) // swiftlint:disable:this xct_specific_matcher
        }
    }

    func test_progress() {
        torrent.send(MockTorrent(progress: 0.189_838))
        var progress: Float?
        item.progress.sink { progress = $0 }.store(in: &observers)
        XCTAssertEqual(progress, 0.189_838)
    }

    func test_progressColor() {
        let pairs: [(TorrentState, UIColor)] = [
            (.downloading, TorrentState.downloading.displayColor),
            (.seeding, TorrentState.seeding.displayColor),
            (.paused, TorrentState.paused.displayColor),
            (.checking, TorrentState.checking.displayColor),
            (.queued, TorrentState.queued.displayColor),
            (.error, TorrentState.error.displayColor),
        ]

        for (state, result) in pairs {
            torrent.send(MockTorrent(standardState: state))
            var color: UIColor?
            item.progressColor.sink { color = $0 }.store(in: &observers)
            XCTAssertEqual(color, result, "\(state)")
        }
    }

    func test_status() {
        let pairs: [(TorrentState, String)] = [
            (.downloading, "Downloading"),
            (.seeding, "Seeding"),
            (.paused, "Paused"),
            (.checking, "Checking"),
            (.queued, "Queued"),
            (.error, "Error"),
        ]

        for (state, result) in pairs {
            torrent.send(MockTorrent(standardState: state))
            var status: String?
            item.status.sink { status = $0 }.store(in: &observers)
            XCTAssertEqual(status, "\(result) (0.00%)")
        }
    }
}
