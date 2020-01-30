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
    private lazy var viewModel = DelugeTorrentListItemViewModel(subject: subject)

    func test_identity_shouldBeEqualToHash() {
        var torrent1 = DelugeTorrent.mock()
        torrent1.hash = "A"

        var torrent2 = DelugeTorrent.mock()
        torrent2.hash = "A"

        XCTAssertEqual(
            DelugeTorrentListItemViewModel(subject: CurrentValueSubject(torrent1)).id,
            DelugeTorrentListItemViewModel(subject: CurrentValueSubject(torrent2)).id
        )

        torrent2.hash = "B"
        XCTAssertNotEqual(
            DelugeTorrentListItemViewModel(subject: CurrentValueSubject(torrent1)).id,
            DelugeTorrentListItemViewModel(subject: CurrentValueSubject(torrent2)).id
        )
    }

    func test_name() {
        let expectation = self.expectation(description: "Value received")
        viewModel.state.name.sink {
            XCTAssertEqual($0, "archlinux-2020.01.01-x86_64.iso")
            expectation.fulfill()
        }.store(in: &observers)
        waitForExpectations(timeout: 0)
    }

    func test_progress() {
        let expectation = self.expectation(description: "Value received")
        viewModel.state.progress.sink {
            XCTAssertEqual($0, 0.189838)
            expectation.fulfill()
        }.store(in: &observers)
        waitForExpectations(timeout: 0)
    }

    func test_progressColor() {
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
            viewModel.state.progressColor.dropFirst().first().sink {
                XCTAssertEqual($0, result)
                expectation.fulfill()
            }.store(in: &observers)
            var torrent = subject.value
            torrent.state = state
            subject.send(torrent)
            waitForExpectations(timeout: 0)
        }
    }

    func test_state() {
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
            viewModel.state.state.dropFirst().first().sink {
                XCTAssertEqual($0, result)
                expectation.fulfill()
            }.store(in: &observers)
            var torrent = subject.value
            torrent.state = state
            subject.send(torrent)
            waitForExpectations(timeout: 0)
        }
    }

    func test_speed_whenDownloading_shouldContainDownloadAndUploadRate() {
        let expectation = self.expectation(description: "Value received")
        viewModel.state.speed.first().sink {
            XCTAssertEqual($0, "↓ 1.5 MB/s ↑ 454.3 KB/s")
            expectation.fulfill()
        }.store(in: &observers)
        waitForExpectations(timeout: 0)
    }

    func test_speed_whenSeeding_shouldContainOnlyUploadRate() {
        var torrent = subject.value
        torrent.state = .seeding
        subject.send(torrent)
        let expectation = self.expectation(description: "Value received")
        viewModel.state.speed.first().sink {
            XCTAssertEqual($0, "↑ 454.3 KB/s")
            expectation.fulfill()
        }.store(in: &observers)
        waitForExpectations(timeout: 0)
    }

    func test_speed_whenInactive_shouldBeEmpty() {
        var torrent = subject.value
        let state: [DelugeTorrent.State] = [.paused, .checking, .queued, .error]
        for state in state {
            let expectation = self.expectation(description: "Value received")
            viewModel.state.speed.dropFirst().first().sink {
                XCTAssertTrue($0.isEmpty)
                expectation.fulfill()
            }.store(in: &observers)
            torrent.state = state
            subject.send(torrent)
            waitForExpectations(timeout: 0)
        }
    }

    func test_progressString() {
        let expectation = self.expectation(description: "Value received")
        viewModel.state.progressString.sink {
            XCTAssertEqual($0, "124.5 MB / 656.0 MB (19%)")
            expectation.fulfill()
        }.store(in: &observers)
        waitForExpectations(timeout: 0)
    }

    let ratioStates = [DelugeTorrent.State.seeding, .paused, .checking, .queued, .error]

    func test_ratio() {
        var torrent = subject.value
        for state in ratioStates {
            let expectation = self.expectation(description: "Value received")
            viewModel.state.ratioOrETA.dropFirst().first().sink {
                XCTAssertEqual($0, "Ratio: 0.4")
                expectation.fulfill()
            }.store(in: &observers)
            torrent.state = state
            subject.send(torrent)
            waitForExpectations(timeout: 0)
        }
    }

    func test_ratio_whenInfinite_shouldFormatProperly() {
        var torrent = subject.value
        torrent.downloaded = 0
        for state in ratioStates {
            let expectation = self.expectation(description: "Value received")
            viewModel.state.ratioOrETA.dropFirst().first().sink {
                XCTAssertEqual($0, "Ratio: ∞")
                expectation.fulfill()
            }.store(in: &observers)
            torrent.state = state
            subject.send(torrent)
            waitForExpectations(timeout: 0)
        }
    }

    func test_ratio_whenNaN_shouldFormatProperly() {
        var torrent = subject.value
        torrent.downloaded = 0
        torrent.uploaded = 0
        for state in ratioStates {
            let expectation = self.expectation(description: "Value received")
            viewModel.state.ratioOrETA.dropFirst().first().sink {
                XCTAssertEqual($0, "Ratio: ∞")
                expectation.fulfill()
            }.store(in: &observers)
            torrent.state = state
            subject.send(torrent)
            waitForExpectations(timeout: 0)
        }
    }

    func test_eta() {
        let expectation = self.expectation(description: "Value received")
        viewModel.state.ratioOrETA.first().sink {
            XCTAssertEqual($0, "6m 1s")
            expectation.fulfill()
        }
        .store(in: &observers)
        waitForExpectations(timeout: 0)
    }

    func test_eta_whenZero_shouldFormatProperly() {
        var torrent = subject.value
        torrent.eta = 0
        subject.send(torrent)
        let expectation = self.expectation(description: "Value received")
        viewModel.state.ratioOrETA.first().sink {
            XCTAssertEqual($0, "∞")
            expectation.fulfill()
        }.store(in: &observers)
        waitForExpectations(timeout: 0)
    }
}
