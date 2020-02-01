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
    private lazy var viewModel = DelugeTorrentDetailHeaderViewModel(subject: subject)

    func test_name() {
        subject.send(.mock(name: "name"))
        let expectation = self.expectation(description: "Value received")
        viewModel.state.name.sink {
            XCTAssertEqual($0, "name")
            expectation.fulfill()
        }.store(in: &observers)
        waitForExpectations(timeout: 0)
    }

    func test_isActive_withActiveStates_shouldBeTrue() {
        for state in [DelugeTorrent.State.downloading, .seeding] {
            subject.send(.mock(state: state))
            var isActive: Bool!
            viewModel.state.isActive.first().sink { isActive = $0 }.store(in: &observers)
            XCTAssertTrue(isActive)
        }
    }

    func test_isActive_withInactiveState_shouldBeFalse() {
        for state in [DelugeTorrent.State.paused, .checking, .queued, .error] {
            subject.send(.mock(state: state))
            var isActive: Bool!
            viewModel.state.isActive.first().sink { isActive = $0 }.store(in: &observers)
            XCTAssertFalse(isActive)
        }
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
            subject.send(.mock(state: state))
            waitForExpectations(timeout: 0)
        }
    }

    func test_status() {
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
            viewModel.state.status.dropFirst().first().sink {
                XCTAssertEqual($0, "\(string) (0.00%)")
                expectation.fulfill()
            }.store(in: &observers)
            subject.send(.mock(state: state))
            waitForExpectations(timeout: 0)
        }
    }
}
