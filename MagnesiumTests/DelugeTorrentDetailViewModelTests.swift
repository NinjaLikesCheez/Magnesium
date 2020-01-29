//
//  DelugeTorrentDetailViewModelTests.swift
//  MagnesiumTests
//
//  Created by James Hurst on 2020-01-22.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import Coordinator
@testable import Magnesium
import Preferences
import XCTest

final class DelugeTorrentDetailViewModelTests: XCTestCase {
    private let subject = CurrentValueSubject<DelugeTorrent, Never>(DelugeTorrent.mock())
    private let client = MockDelugeClient()
    private let preferences = MockPreferences()
    private var viewModel: DelugeTorrentDetailViewModel!
    private var observers = [AnyCancellable]()

    override func setUp() {
        super.setUp()
        viewModel = DelugeTorrentDetailViewModel(
            subject: subject,
            client: client,
            preferences: preferences,
            refresher: MockDelugeRefresher(client: client)
        )
    }

    func testNoAutoUpdateIfNotDidAppear() throws {
        preferences.set(1, for: PreferenceKeys.autoRefreshInterval)
        client.requests.reset()
        let expectation = self.expectation(description: "Update")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            XCTAssertEqual(self.client.requests, MockDelugeClient.Requests(torrentFiles: 0))
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.2)
    }

    func testAutoUpdate() throws {
        preferences.set(1, for: PreferenceKeys.autoRefreshInterval)
        client.requests.reset()
        viewModel.handle(.appear)

        let firstCheck = expectation(description: "First check")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            XCTAssertEqual(self.client.requests, MockDelugeClient.Requests(torrentFiles: 1))
            firstCheck.fulfill()
        }
        waitForExpectations(timeout: 1.1)

        viewModel.handle(.disappear)

        let secondCheck = expectation(description: "Second check")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            XCTAssertEqual(self.client.requests, MockDelugeClient.Requests(torrentFiles: 1))
            secondCheck.fulfill()
        }
        waitForExpectations(timeout: 1.2)
    }

    func testAutoUpdateStopsWhenDisabled() throws {
        preferences.set(1, for: PreferenceKeys.autoRefreshInterval)
        client.requests.reset()
        viewModel.handle(.appear)

        let firstCheck = expectation(description: "First check")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            XCTAssertEqual(self.client.requests, MockDelugeClient.Requests(torrentFiles: 1))
            firstCheck.fulfill()
        }
        waitForExpectations(timeout: 1.2)

        preferences.set(0, for: PreferenceKeys.autoRefreshInterval)

        let secondCheck = expectation(description: "Second check")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            XCTAssertEqual(self.client.requests, MockDelugeClient.Requests(torrentFiles: 1))
            secondCheck.fulfill()
        }
        waitForExpectations(timeout: 1.2)
    }

    func testRefreshError() {
        client.errors.torrentFiles = true

        var alert: Alert?
        viewModel.events.first().sink {
            guard case let .alert(inner, source: _) = $0 else {
                XCTFail("Unexpected event")
                return
            }
            alert = inner
        }.store(in: &observers)

        viewModel.handle(.refresh)
        XCTAssertEqual(alert?.title, "Update Failed")
    }

    func testHasHeader() {
        let expectation = self.expectation(description: "Value received")
        viewModel.state.sections.sink { sections in
            let section = sections[0]
            XCTAssertEqual(section.type, .header)
            XCTAssertEqual(section.items.count, 1)
            expectation.fulfill()
        }.store(in: &observers)
        waitForExpectations(timeout: 0)
    }

    private func getInfoRows(in section: TorrentDetailSection) -> [(String, String)] {
        XCTAssertEqual(section.type, .info)
        return section.items.compactMap { item -> (String, String)? in
            switch item {
            case let .info(name, valuePublisher):
                let expectation = self.expectation(description: "Value received")
                var value: String!
                valuePublisher.first().sink {
                    value = $0
                    expectation.fulfill()
                }.store(in: &self.observers)
                self.wait(for: [expectation], timeout: 0)
                return (name, value)
            default:
                XCTFail("Unexpected item")
                return nil
            }
        }
    }

    func testInfoRows() {
        let expected: [(String, String)] = [
            ("Size", "656.0 MB"),
            ("Download Speed", "1.5 MB/s"),
            ("Upload Speed", "454.3 KB/s"),
            ("Downloaded", "124.5 MB"),
            ("Uploaded", "53.8 MB"),
            ("ETA", "6m 1s"),
            ("Ratio", "0.432"),
            ("Peers", "2 (35)"),
            ("Seeds", "70 (832)"),
        ]

        let expectation = self.expectation(description: "Value received")
        viewModel.state.sections.sink { sections in
            let rows = self.getInfoRows(in: sections[1])
            XCTAssertEqual(rows.map { "\($0.0): \($0.1)" }, expected.map { "\($0.0): \($0.1)" })
            expectation.fulfill()
        }.store(in: &observers)
        wait(for: [expectation], timeout: 0)
    }

    func testInfiniteETA() {
        var torrent = subject.value
        torrent.eta = 0
        subject.send(torrent)

        let expectation = self.expectation(description: "Value received")
        viewModel.state.sections.sink { sections in
            let eta = self.getInfoRows(in: sections[1]).first { $0.0 == "ETA" }!
            XCTAssertEqual(eta.1, "∞")
            expectation.fulfill()
        }.store(in: &observers)
        wait(for: [expectation], timeout: 0)
    }

    func testInfiniteRatio() {
        var torrent = subject.value
        torrent.downloaded = 0
        subject.send(torrent)

        let expectation = self.expectation(description: "Value received")
        viewModel.state.sections.sink { sections in
            let eta = self.getInfoRows(in: sections[1]).first { $0.0 == "Ratio" }!
            XCTAssertEqual(eta.1, "∞")
            expectation.fulfill()
        }.store(in: &observers)
        wait(for: [expectation], timeout: 0)
    }

    func testNanRatio() {
        var torrent = subject.value
        torrent.downloaded = 0
        torrent.uploaded = 0
        subject.send(torrent)

        let expectation = self.expectation(description: "Value received")
        viewModel.state.sections.sink { sections in
            let eta = self.getInfoRows(in: sections[1]).first { $0.0 == "Ratio" }!
            XCTAssertEqual(eta.1, "∞")
            expectation.fulfill()
        }.store(in: &observers)
        wait(for: [expectation], timeout: 0)
    }

    func testTrackers() {
        let expected = ["udp://tracker.archlinux.org:6969", "http://tracker.archlinux.org:6969/announce"]

        let expectation = self.expectation(description: "Value received")
        viewModel.state.sections.sink { sections in
            let section = sections[2]
            XCTAssertEqual(section.type, .trackers)

            let trackers = section.items.compactMap { item -> String? in
                switch item {
                case let .tracker(tracker):
                    return tracker
                default:
                    XCTFail("Unexpected item")
                    return nil
                }
            }

            XCTAssertEqual(trackers, expected)
            expectation.fulfill()
        }.store(in: &observers)
        wait(for: [expectation], timeout: 0)
    }

    func testFilesSorted() {
        let expectation = self.expectation(description: "Value received")
        viewModel.state.sections.sink { sections in
            let section = sections[3]
            XCTAssertEqual(section.type, .files)

            let files = section.items.compactMap { item -> String? in
                switch item {
                case let .file(viewModel):
                    return viewModel.state.name
                default:
                    XCTFail("Unexpected item")
                    return nil
                }
            }
            XCTAssertEqual(files, ["file.r00", "file.r01", "file.rar"])
            expectation.fulfill()
        }.store(in: &observers)
        waitForExpectations(timeout: 0)
    }

    func testMoreOptionsAlert() {
        var alert: Alert?
        viewModel.events.first().sink {
            guard case let .alert(inner, source: _) = $0 else {
                XCTFail("Unexpected event")
                return
            }
            alert = inner
        }.store(in: &observers)

        viewModel.handle(.moreOptions(source: .view(UIView(), rect: .zero)))
        let expected = ["Force Recheck", "Cancel"]
        XCTAssertEqual(alert?.actions.map { $0.title ?? "" }, expected)
    }

    func testForceRecheck() {
        client.requests.reset()

        var alert: Alert?
        viewModel.events.first().sink {
            guard case let .alert(inner, source: _) = $0 else {
                XCTFail("Unexpected event")
                return
            }
            alert = inner
        }.store(in: &observers)

        viewModel.handle(.moreOptions(source: .view(UIView(), rect: .zero)))
        let recheck = alert!.actions[0].handler!
        recheck()
        XCTAssertEqual(client.requests, MockDelugeClient.Requests(torrents: 1, recheck: 1))
    }

    func testForceRecheckError() {
        client.errors.recheck = true
        client.requests.reset()

        var optionsAlert: Alert?
        viewModel.events.first().sink {
            guard case let .alert(inner, source: _) = $0 else {
                XCTFail("Unexpected event")
                return
            }
            optionsAlert = inner
        }.store(in: &observers)
        viewModel.handle(.moreOptions(source: .view(UIView(), rect: .zero)))
        let recheck = optionsAlert!.actions[0].handler!

        var errorAlert: Alert?
        viewModel.events.first().sink {
            guard case let .alert(inner, source: _) = $0 else {
                XCTFail("Unexpected event")
                return
            }
            errorAlert = inner
        }.store(in: &observers)
        recheck()
        XCTAssertEqual(errorAlert?.title, "Failed to Recheck")
        XCTAssertEqual(client.requests, MockDelugeClient.Requests())
    }

    func testPause() {
        client.requests.reset()
        viewModel.handle(.pause)
        XCTAssertEqual(client.requests, MockDelugeClient.Requests(torrents: 1, pause: 1))
    }

    func testPauseError() {
        client.errors.pause = true
        client.requests.reset()

        var errorAlert: Alert?
        viewModel.events.first().sink {
            guard case let .alert(inner, source: _) = $0 else {
                XCTFail("Unexpected event")
                return
            }
            errorAlert = inner
        }.store(in: &observers)

        viewModel.handle(.pause)
        XCTAssertEqual(errorAlert?.title, "Failed to Pause")
        XCTAssertEqual(client.requests, MockDelugeClient.Requests())
    }

    func testResume() {
        client.requests.reset()
        viewModel.handle(.resume)
        XCTAssertEqual(client.requests, MockDelugeClient.Requests(torrents: 1, resume: 1))
    }

    func testResumeError() {
        client.errors.resume = true
        client.requests.reset()

        var errorAlert: Alert?
        viewModel.events.first().sink {
            guard case let .alert(inner, source: _) = $0 else {
                XCTFail("Unexpected event")
                return
            }
            errorAlert = inner
        }.store(in: &observers)

        viewModel.handle(.resume)
        XCTAssertEqual(errorAlert?.title, "Failed to Resume")
        XCTAssertEqual(client.requests, MockDelugeClient.Requests())
    }

    func testRemoveAlert() {
        client.requests.reset()

        var alert: Alert?
        viewModel.events.first().sink {
            guard case let .alert(inner, source: _) = $0 else {
                XCTFail("Unexpected event")
                return
            }
            alert = inner
        }.store(in: &observers)

        viewModel.handle(.remove(source: .view(UIView(), rect: .zero)))
        let expected = ["Keep Data", "Remove Data", "Cancel"]
        XCTAssertEqual(alert?.actions.map { $0.title ?? "" }, expected)
    }

    func testRemoveKeepData() {
        client.requests.reset()

        var alert: Alert?
        viewModel.events.first().sink {
            guard case let .alert(inner, source: _) = $0 else {
                XCTFail("Unexpected event")
                return
            }
            alert = inner
        }.store(in: &observers)
        viewModel.handle(.remove(source: .view(UIView(), rect: .zero)))
        let remove = alert!.actions[0].handler!

        var event: TorrentDetailEvent?
        viewModel.events.first().sink { inner in
            event = inner
        }.store(in: &observers)
        remove()
        XCTAssertEqual(client.requests, MockDelugeClient.Requests(torrents: 1, remove: [false]))

        guard case .complete = event else {
            XCTFail("Unexpected event")
            return
        }
    }

    func testRemoveKeepDataError() {
        client.errors.removeKeepData = true
        client.requests.reset()

        var optionAlert: Alert?
        viewModel.events.first().sink {
            guard case let .alert(inner, source: _) = $0 else {
                XCTFail("Unexpected event")
                return
            }
            optionAlert = inner
        }.store(in: &observers)
        viewModel.handle(.remove(source: .view(UIView(), rect: .zero)))
        let remove = optionAlert!.actions[0].handler!

        var errorAlert: Alert?
        viewModel.events.first().sink {
            guard case let .alert(inner, source: _) = $0 else {
                XCTFail("Unexpected event")
                return
            }
            errorAlert = inner
        }.store(in: &observers)
        remove()
        XCTAssertEqual(errorAlert?.title, "Failed to Remove")
        XCTAssertEqual(client.requests, MockDelugeClient.Requests())
    }

    func testRemoveWithData() {
        client.requests.reset()

        var alert: Alert?
        viewModel.events.first().sink {
            guard case let .alert(inner, source: _) = $0 else {
                XCTFail("Unexpected event")
                return
            }
            alert = inner
        }.store(in: &observers)

        viewModel.handle(.remove(source: .view(UIView(), rect: .zero)))
        let remove = alert!.actions[1].handler!
        remove()
        XCTAssertEqual(client.requests, MockDelugeClient.Requests(torrents: 1, remove: [true]))
    }

    func testRemoveWithDataError() {
        client.errors.removeWithData = true
        client.requests.reset()

        var optionAlert: Alert?
        viewModel.events.first().sink {
            guard case let .alert(inner, source: _) = $0 else {
                XCTFail("Unexpected event")
                return
            }
            optionAlert = inner
        }.store(in: &observers)
        viewModel.handle(.remove(source: .view(UIView(), rect: .zero)))
        let remove = optionAlert!.actions[1].handler!

        var errorAlert: Alert?
        viewModel.events.first().sink {
            guard case let .alert(inner, source: _) = $0 else {
                XCTFail("Unexpected event")
                return
            }
            errorAlert = inner
        }.store(in: &observers)
        remove()
        XCTAssertEqual(errorAlert?.title, "Failed to Remove")
        XCTAssertEqual(client.requests, MockDelugeClient.Requests())
    }
}

// swiftlint:disable:next static_operator
private func == (lhs: (String, String), rhs: (String, String)) -> Bool {
    return lhs.0 == rhs.0 && lhs.1 == rhs.1
}
