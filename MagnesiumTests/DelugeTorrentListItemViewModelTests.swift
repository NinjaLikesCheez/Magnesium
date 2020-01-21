//
//  DelugeTorrentListItemViewModelTests.swift
//  MagnesiumTests
//
//  Created by James Hurst on 2020-01-18.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
@testable import Magnesium
import XCTest

class DelugeTorrentListItemViewModelTests: XCTestCase {
    private var observers = [AnyCancellable]()

    private let subject = CurrentValueSubject<DelugeTorrent, Never>(DelugeTorrent(
        hash: "A",
        name: "",
        state: .downloading,
        dateAdded: Date(),
        downloadRate: 0,
        uploadRate: 0,
        eta: 0,
        progress: 0,
        downloaded: 0,
        uploaded: 0,
        size: 0,
        seeds: 0,
        totalSeeds: 0,
        peers: 0,
        totalPeers: 0,
        trackers: [],
        label: ""
    ))

    private lazy var viewModel = DelugeTorrentListItemViewModel(torrentSubject: subject)

    func testEquality() {
        var torrent = DelugeTorrent(
            hash: "A",
            name: "",
            state: .seeding,
            dateAdded: Date(),
            downloadRate: 0,
            uploadRate: 0,
            eta: 0,
            progress: 0,
            downloaded: 0,
            uploaded: 0,
            size: 0,
            seeds: 0,
            totalSeeds: 0,
            peers: 0,
            totalPeers: 0,
            trackers: [],
            label: ""
        )

        XCTAssertEqual(
            DelugeTorrentListItemViewModel(torrentSubject: subject),
            DelugeTorrentListItemViewModel(torrentSubject: CurrentValueSubject(torrent))
        )

        torrent.hash = "B"
        XCTAssertNotEqual(
            DelugeTorrentListItemViewModel(torrentSubject: subject),
            DelugeTorrentListItemViewModel(torrentSubject: CurrentValueSubject(torrent))
        )
    }

    func testName() {
        let expectation = self.expectation(description: "Value received")
        viewModel.name
            .dropFirst()
            .sink {
                XCTAssertEqual($0, "new")
                expectation.fulfill()
            }
            .store(in: &observers)
        var torrent = subject.value
        torrent.name = "new"
        subject.send(torrent)
        waitForExpectations(timeout: 0)
    }

    func testProgress() {
        let expectation = self.expectation(description: "Value received")
        viewModel.progress
            .dropFirst()
            .sink {
                XCTAssertEqual($0, 0.9)
                expectation.fulfill()
            }
            .store(in: &observers)
        var torrent = subject.value
        torrent.progress = 0.9
        subject.send(torrent)
        waitForExpectations(timeout: 0)
    }

    func testProgressColor() {
        let pairs: [(DelugeTorrent.State, UIColor)] = [
            (.downloading, TorrentState.downloading.displayColor),
            (.seeding, TorrentState.seeding.displayColor),
            (.paused, TorrentState.paused.displayColor),
            (.checking, TorrentState.checking.displayColor),
            (.queued, TorrentState.queued.displayColor),
            (.error, TorrentState.error.displayColor),
        ]

        for (state, result) in pairs {
            let expectation = self.expectation(description: "Value received")
            viewModel.progressColor
                .dropFirst()
                .first()
                .sink {
                    XCTAssertEqual($0, result)
                    expectation.fulfill()
                }
                .store(in: &observers)
            var torrent = subject.value
            torrent.state = state
            subject.send(torrent)
            waitForExpectations(timeout: 0)
        }
    }

    func testState() {
        let pairs: [(DelugeTorrent.State, String)] = [
            (.downloading, "Downloading"),
            (.seeding, "Seeding"),
            (.paused, "Paused"),
            (.checking, "Checking"),
            (.queued, "Queued"),
            (.error, "Error"),
        ]

        for (state, result) in pairs {
            let expectation = self.expectation(description: "Value received")
            viewModel.state
                .dropFirst()
                .first()
                .sink {
                    XCTAssertEqual($0, result)
                    expectation.fulfill()
                }
                .store(in: &observers)
            var torrent = subject.value
            torrent.state = state
            subject.send(torrent)
            waitForExpectations(timeout: 0)
        }
    }

    func testSpeed() {
        let expectation = self.expectation(description: "Value received")
        viewModel.speed
            .dropFirst()
            .sink {
                XCTAssertEqual($0, "↓ 8.1 MB/s ↑ 1.2 MB/s")
                expectation.fulfill()
            }
            .store(in: &observers)
        var torrent = subject.value
        torrent.downloadRate = 8_483_920
        torrent.uploadRate = 1_249_493
        subject.send(torrent)

        waitForExpectations(timeout: 0)
    }

    func testProgressString() {
        let expectation = self.expectation(description: "Value received")
        viewModel.progressString
            .dropFirst()
            .sink {
                XCTAssertEqual($0, "211.9 MB / 460.6 MB (46%)")
                expectation.fulfill()
            }
            .store(in: &observers)
        var torrent = subject.value
        torrent.size = 482_941_354
        torrent.progress = 0.46
        torrent.downloaded = Int64(Float(torrent.size) * torrent.progress)
        subject.send(torrent)
        waitForExpectations(timeout: 0)
    }

    func testRatio() {
        let states: [DelugeTorrent.State] = [
            .seeding,
            .paused,
            .checking,
            .queued,
            .error,
        ]

        for state in states {
            let expectation = self.expectation(description: "Value received")
            viewModel.ratioOrETA
                .dropFirst()
                .first()
                .sink {
                    XCTAssertEqual($0, "Ratio: 1.4")
                    expectation.fulfill()
                }
                .store(in: &observers)

            var torrent = subject.value
            torrent.state = state
            torrent.downloaded = 7_529_018_233
            torrent.uploaded = Int64(Double(torrent.downloaded) * 1.42)
            subject.send(torrent)
            waitForExpectations(timeout: 0)

            let infiniteExpectation = self.expectation(description: "Value received")
            viewModel.ratioOrETA
                .dropFirst()
                .first()
                .sink {
                    XCTAssertEqual($0, "Ratio: ∞")
                    infiniteExpectation.fulfill()
                }
                .store(in: &observers)
            torrent.downloaded = 0
            subject.send(torrent)
            waitForExpectations(timeout: 0)
        }
    }

    func testETA() {
        let expectation = self.expectation(description: "Value received")
        viewModel.ratioOrETA
            .dropFirst()
            .first()
            .sink {
                XCTAssertEqual($0, "2d 21h 1m 12s")
                expectation.fulfill()
            }
            .store(in: &observers)

        var torrent = subject.value
        torrent.state = .downloading
        torrent.eta = 102 * 84 * 29
        subject.send(torrent)
        waitForExpectations(timeout: 0)

        let infiniteExpectation = self.expectation(description: "Value received")
        viewModel.ratioOrETA
            .dropFirst()
            .first()
            .sink {
                XCTAssertEqual($0, "∞")
                infiniteExpectation.fulfill()
            }
            .store(in: &observers)
        torrent.eta = 0
        subject.send(torrent)
        waitForExpectations(timeout: 0)
    }
}
