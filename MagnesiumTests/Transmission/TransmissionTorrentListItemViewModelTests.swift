//
//  TransmissionTorrentListItemViewModelTests.swift
//  MagnesiumTests
//
//  Created by James Hurst on 2020-02-02.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
@testable import Magnesium
import XCTest

class TransmissionTorrentListItemViewModelTests: XCTestCase {
    private var observers = [AnyCancellable]()
    private let subject = CurrentValueSubject<TransmissionTorrent, Never>(.mock())
    private lazy var viewModel = StandardTorrentListItemViewModel(subject: subject)

    func test_identity_shouldBeEqualToHash() {
        let torrent1 = TransmissionTorrent.mock(hash: "A")
        var torrent2 = TransmissionTorrent.mock(hash: "A")
        XCTAssertEqual(
            StandardTorrentListItemViewModel(subject: CurrentValueSubject(torrent1)).id,
            StandardTorrentListItemViewModel(subject: CurrentValueSubject(torrent2)).id
        )

        torrent2.hash = "B"
        XCTAssertNotEqual(
            StandardTorrentListItemViewModel(subject: CurrentValueSubject(torrent1)).id,
            StandardTorrentListItemViewModel(subject: CurrentValueSubject(torrent2)).id
        )
    }

    func test_name() {
        subject.send(.mock(name: "name"))
        let expectation = self.expectation(description: "Value received")
        viewModel.state.name.sink {
            XCTAssertEqual($0, "name")
            expectation.fulfill()
        }.store(in: &observers)
        waitForExpectations(timeout: 0)
    }

    func test_progress() {
        subject.send(.mock(progress: 0.189838))
        let expectation = self.expectation(description: "Value received")
        viewModel.state.progress.sink {
            XCTAssertEqual($0, 0.189838)
            expectation.fulfill()
        }.store(in: &observers)
        waitForExpectations(timeout: 0)
    }

    func test_progressColor() {
        let pairs: [(TransmissionTorrent.Status, UIColor)] = [
            (.downloading, TorrentState.downloading.displayColor),
            (.seeding, TorrentState.seeding.displayColor),
            (.paused, TorrentState.paused.displayColor),
            (.checking, TorrentState.checking.displayColor),
            (.checkQueued, TorrentState.queued.displayColor),
            (.downloadQueued, TorrentState.queued.displayColor),
            (.seedQueued, TorrentState.queued.displayColor),
            (.isolated, TorrentState.error.displayColor),
        ]

        for (status, result) in pairs {
            subject.send(.mock(status: status))
            let expectation = self.expectation(description: "Value received")
            viewModel.state.progressColor.first().sink {
                XCTAssertEqual($0, result)
                expectation.fulfill()
            }.store(in: &observers)
            waitForExpectations(timeout: 0)
        }
    }

    func test_state() {
        let pairs: [(TransmissionTorrent.Status, String)] = [
            (.downloading, "Downloading"),
            (.seeding, "Seeding"),
            (.paused, "Paused"),
            (.checking, "Checking"),
            (.checkQueued, "Queued"),
            (.downloadQueued, "Queued"),
            (.seedQueued, "Queued"),
            (.isolated, "Error"),
        ]

        for (status, result) in pairs {
            subject.send(.mock(status: status))
            let expectation = self.expectation(description: "Value received")
            viewModel.state.state.first().sink {
                XCTAssertEqual($0, result)
                expectation.fulfill()
            }.store(in: &observers)
            waitForExpectations(timeout: 0)
        }
    }

    func test_speed_whenDownloading_shouldContainDownloadAndUploadRate() {
        subject.send(.mock(downloadRate: 1_540_527, uploadRate: 465_158))
        let expectation = self.expectation(description: "Value received")
        viewModel.state.speed.first().sink {
            XCTAssertEqual($0, "↓ 1.5 MB/s ↑ 454.3 KB/s")
            expectation.fulfill()
        }.store(in: &observers)
        waitForExpectations(timeout: 0)
    }

    func test_speed_whenSeeding_shouldContainOnlyUploadRate() {
        subject.send(.mock(status: .seeding, downloadRate: 1_540_527, uploadRate: 465_158))
        let expectation = self.expectation(description: "Value received")
        viewModel.state.speed.first().sink {
            XCTAssertEqual($0, "↑ 454.3 KB/s")
            expectation.fulfill()
        }.store(in: &observers)
        waitForExpectations(timeout: 0)
    }

    func test_speed_whenInactive_shouldBeEmpty() {
        let statuses: [TransmissionTorrent.Status] = [
            .checking,
            .checkQueued,
            .downloadQueued,
            .seedQueued,
            .isolated,
        ]
        for status in statuses {
            subject.send(.mock(status: status))
            let expectation = self.expectation(description: "Value received")
            viewModel.state.speed.first().sink {
                XCTAssertTrue($0.isEmpty)
                expectation.fulfill()
            }.store(in: &observers)
            waitForExpectations(timeout: 0)
        }
    }

    func test_progressString() {
        subject.send(.mock(progress: 0.189838, downloaded: 130_583_716, size: 687_865_856))
        let expectation = self.expectation(description: "Value received")
        viewModel.state.progressString.sink {
            XCTAssertEqual($0, "124.5 MB / 656.0 MB (19%)")
            expectation.fulfill()
        }.store(in: &observers)
        waitForExpectations(timeout: 0)
    }

    private let ratioStatuses: [TransmissionTorrent.Status] = [
        .paused,
        .checking,
        .checkQueued,
        .downloadQueued,
        .seedQueued,
        .isolated,
    ]

    func test_ratio() {
        for status in ratioStatuses {
            subject.send(.mock(status: status, downloaded: 10000, uploaded: 4254))
            let expectation = self.expectation(description: "Value received")
            viewModel.state.ratioOrETA.first().sink {
                XCTAssertEqual($0, "Ratio: 0.4")
                expectation.fulfill()
            }.store(in: &observers)
            waitForExpectations(timeout: 0)
        }
    }

    func test_ratio_whenInfinite_shouldFormatProperly() {
        for status in ratioStatuses {
            subject.send(.mock(status: status, uploaded: 1))
            XCTAssertTrue(subject.value.ratio.isInfinite)
            let expectation = self.expectation(description: "Value received")
            viewModel.state.ratioOrETA.first().sink {
                XCTAssertEqual($0, "Ratio: ∞")
                expectation.fulfill()
            }.store(in: &observers)
            waitForExpectations(timeout: 0)
        }
    }

    func test_ratio_whenNaN_shouldFormatProperly() {
        for status in ratioStatuses {
            subject.send(.mock(status: status))
            XCTAssertTrue(subject.value.ratio.isNaN)
            let expectation = self.expectation(description: "Value received")
            viewModel.state.ratioOrETA.first().sink {
                XCTAssertEqual($0, "Ratio: ∞")
                expectation.fulfill()
            }.store(in: &observers)
            waitForExpectations(timeout: 0)
        }
    }

    func test_eta() {
        subject.send(.mock(eta: 361))
        let expectation = self.expectation(description: "Value received")
        viewModel.state.ratioOrETA.first().sink {
            XCTAssertEqual($0, "6m 1s")
            expectation.fulfill()
        }
        .store(in: &observers)
        waitForExpectations(timeout: 0)
    }

    func test_eta_whenZero_shouldFormatProperly() {
        let expectation = self.expectation(description: "Value received")
        viewModel.state.ratioOrETA.first().sink {
            XCTAssertEqual($0, "∞")
            expectation.fulfill()
        }.store(in: &observers)
        waitForExpectations(timeout: 0)
    }
}
