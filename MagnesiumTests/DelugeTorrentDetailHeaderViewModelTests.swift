//
//  DelugeTorrentDetailHeaderViewModelTests.swift
//  MagnesiumTests
//
//  Created by James Hurst on 2020-01-26.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
@testable import Magnesium
import XCTest

class DelugeTorrentDetailHeaderViewModelTests: XCTestCase {
    private var observers = [AnyCancellable]()
    private let subject = CurrentValueSubject<DelugeTorrent, Never>(.mock())
    private lazy var viewModel = DelugeTorrentDetailHeaderViewModel(torrentSubject: subject)

    func testName() {
        let expectation = self.expectation(description: "Value received")
        viewModel.name.sink {
            XCTAssertEqual($0, "archlinux-2020.01.01-x86_64.iso")
            expectation.fulfill()
        }.store(in: &observers)
        waitForExpectations(timeout: 0)
    }

    func testActiveStates() {
        var torrent = subject.value
        for state in [DelugeTorrent.State.downloading, .seeding] {
            var isActive: Bool!
            viewModel.isActive.dropFirst().first().sink { isActive = $0 }.store(in: &observers)
            torrent.state = state
            subject.send(torrent)
            XCTAssertTrue(isActive)
        }
    }

    func testInactiveStates() {
        var torrent = subject.value
        for state in [DelugeTorrent.State.paused, .checking, .queued, .error] {
            var isActive: Bool!
            viewModel.isActive.dropFirst().first().sink { isActive = $0 }.store(in: &observers)
            torrent.state = state
            subject.send(torrent)
            XCTAssertFalse(isActive)
        }
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

    func testStatus() {
        let pairs: [(DelugeTorrent.State, String)] = [
            (.downloading, "Downloading"),
            (.seeding, "Seeding"),
            (.paused, "Paused"),
            (.checking, "Checking"),
            (.queued, "Queued"),
            (.error, "Error"),
        ]

        for (state, string) in pairs {
            let expectation = self.expectation(description: "Value received")
            viewModel.status.dropFirst().first().sink {
                XCTAssertEqual($0, "\(string) (18.98%)")
                expectation.fulfill()
            }.store(in: &observers)
            var torrent = subject.value
            torrent.state = state
            subject.send(torrent)
            waitForExpectations(timeout: 0)
        }
    }
}
