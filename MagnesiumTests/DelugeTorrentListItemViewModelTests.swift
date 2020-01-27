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
    private let subject = CurrentValueSubject<DelugeTorrent, Never>(.mock())
    private lazy var viewModel = DelugeTorrentListItemViewModel(torrentSubject: subject)

    func testEquality() {
        var torrent1 = DelugeTorrent.mock()
        torrent1.hash = "A"

        var torrent2 = DelugeTorrent.mock()
        torrent2.hash = "A"

        XCTAssertEqual(
            DelugeTorrentListItemViewModel(torrentSubject: CurrentValueSubject(torrent1)),
            DelugeTorrentListItemViewModel(torrentSubject: CurrentValueSubject(torrent2))
        )

        torrent2.hash = "B"
        XCTAssertNotEqual(
            DelugeTorrentListItemViewModel(torrentSubject: CurrentValueSubject(torrent1)),
            DelugeTorrentListItemViewModel(torrentSubject: CurrentValueSubject(torrent2))
        )
    }

    func testName() {
        let expectation = self.expectation(description: "Value received")
        viewModel.name.sink {
            XCTAssertEqual($0, "archlinux-2020.01.01-x86_64.iso")
            expectation.fulfill()
        }.store(in: &observers)
        waitForExpectations(timeout: 0)
    }

    func testProgress() {
        let expectation = self.expectation(description: "Value received")
        viewModel.progress.sink {
            XCTAssertEqual($0, 0.189838)
            expectation.fulfill()
        }.store(in: &observers)
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
            viewModel.progressColor.dropFirst().first().sink {
                XCTAssertEqual($0, result)
                expectation.fulfill()
            }.store(in: &observers)
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
            viewModel.state.dropFirst().first().sink {
                XCTAssertEqual($0, result)
                expectation.fulfill()
            }.store(in: &observers)
            var torrent = subject.value
            torrent.state = state
            subject.send(torrent)
            waitForExpectations(timeout: 0)
        }
    }

    func testSpeed() {
        let expectation = self.expectation(description: "Value received")
        viewModel.speed.first().sink {
            XCTAssertEqual($0, "↓ 1.5 MB/s ↑ 454.3 KB/s")
            expectation.fulfill()
        }.store(in: &observers)
        waitForExpectations(timeout: 0)

        let seedingExpectation = self.expectation(description: "Value received")
        viewModel.speed.dropFirst().first().sink {
            XCTAssertEqual($0, "↑ 454.3 KB/s")
            seedingExpectation.fulfill()
        }.store(in: &observers)
        var torrent = subject.value
        torrent.state = .seeding
        subject.send(torrent)
        waitForExpectations(timeout: 0)

        let emptyStates: [DelugeTorrent.State] = [.paused, .checking, .queued, .error]
        for state in emptyStates {
            let expectation = self.expectation(description: "Value received")
            viewModel.speed.dropFirst().first().sink {
                XCTAssertTrue($0.isEmpty)
                expectation.fulfill()
            }.store(in: &observers)
            torrent.state = state
            subject.send(torrent)
            waitForExpectations(timeout: 0)
        }
    }

    func testProgressString() {
        let expectation = self.expectation(description: "Value received")
        viewModel.progressString.sink {
            XCTAssertEqual($0, "124.5 MB / 656.0 MB (19%)")
            expectation.fulfill()
        }.store(in: &observers)
        waitForExpectations(timeout: 0)
    }

    let ratioStates = [DelugeTorrent.State.seeding, .paused, .checking, .queued, .error]

    func testRatio() {
        var torrent = subject.value
        for state in ratioStates {
            let expectation = self.expectation(description: "Value received")
            viewModel.ratioOrETA.dropFirst().first().sink {
                XCTAssertEqual($0, "Ratio: 0.4")
                expectation.fulfill()
            }.store(in: &observers)
            torrent.state = state
            subject.send(torrent)
            waitForExpectations(timeout: 0)
        }
    }

    func testInfiniteRatio() {
        var torrent = subject.value
        torrent.downloaded = 0
        for state in ratioStates {
            let expectation = self.expectation(description: "Value received")
            viewModel.ratioOrETA.dropFirst().first().sink {
                XCTAssertEqual($0, "Ratio: ∞")
                expectation.fulfill()
            }.store(in: &observers)
            torrent.state = state
            subject.send(torrent)
            waitForExpectations(timeout: 0)
        }
    }

    func testNanRatio() {
        var torrent = subject.value
        torrent.downloaded = 0
        torrent.uploaded = 0
        for state in ratioStates {
            let expectation = self.expectation(description: "Value received")
            viewModel.ratioOrETA.dropFirst().first().sink {
                XCTAssertEqual($0, "Ratio: ∞")
                expectation.fulfill()
            }.store(in: &observers)
            torrent.state = state
            subject.send(torrent)
            waitForExpectations(timeout: 0)
        }
    }

    func testETA() {
        let expectation = self.expectation(description: "Value received")
        viewModel.ratioOrETA.first().sink {
            XCTAssertEqual($0, "6m 1s")
            expectation.fulfill()
        }
        .store(in: &observers)
        waitForExpectations(timeout: 0)

        let infiniteExpectation = self.expectation(description: "Value received")
        viewModel.ratioOrETA.dropFirst().first().sink {
            XCTAssertEqual($0, "∞")
            infiniteExpectation.fulfill()
        }.store(in: &observers)
        var torrent = subject.value
        torrent.eta = 0
        subject.send(torrent)
        waitForExpectations(timeout: 0)
    }
}
