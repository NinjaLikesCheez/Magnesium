//
//  TransmissionTorrentDetailHeaderViewModelTests.swift
//  MagnesiumTests
//
//  Created by James Hurst on 2020-02-02.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
@testable import Magnesium
import XCTest

class TransmissionTorrentDetailHeaderViewModelTests: XCTestCase {
    typealias Torrent = TransmissionTorrentDetailViewModel.Torrent
    private var observers = [AnyCancellable]()
    private let subject = CurrentValueSubject<TransmissionTorrent, Never>(.mock())
    private lazy var mappedSubject = CurrentValueSubject<Torrent, Never>(Torrent(subject.value))
    private lazy var viewModel = StandardTorrentDetailHeaderViewModel(subject: mappedSubject)

    override func setUp() {
        super.setUp()
        subject.sink { [weak self] in self?.mappedSubject.send(Torrent($0)) }.store(in: &observers)
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

    func test_isActive_withActiveStates_shouldBeTrue() {
        for status in [TransmissionTorrent.Status.downloading, .seeding] {
            subject.send(.mock(status: status))
            var isActive: Bool!
            viewModel.state.isActive.first().sink { isActive = $0 }.store(in: &observers)
            XCTAssertTrue(isActive)
        }
    }

    func test_isActive_withInactiveState_shouldBeFalse() {
        let statuses: [TransmissionTorrent.Status] = [
            .paused,
            .checking,
            .checkQueued,
            .downloadQueued,
            .seedQueued,
            .isolated,
        ]

        for status in statuses {
            subject.send(.mock(status: status))
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
            let expectation = self.expectation(description: "Value received")
            viewModel.state.progressColor.dropFirst().first().sink {
                XCTAssertEqual($0, result)
                expectation.fulfill()
            }.store(in: &observers)
            subject.send(.mock(status: status))
            waitForExpectations(timeout: 0)
        }
    }

    func test_status() {
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

        for (status, string) in pairs {
            let expectation = self.expectation(description: "Value received")
            viewModel.state.status.dropFirst().first().sink {
                XCTAssertEqual($0, "\(string) (0.00%)")
                expectation.fulfill()
            }.store(in: &observers)
            subject.send(.mock(status: status))
            waitForExpectations(timeout: 0)
        }
    }
}
