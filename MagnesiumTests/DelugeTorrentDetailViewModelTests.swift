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

    func test_autoUpdate_whenNotAppeared_shouldNotFire() {
        preferences.set(0.1, for: PreferenceKeys.autoRefreshInterval)
        client.requests.reset()
        let expectation = self.expectation(description: "Check")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.11) {
            XCTAssertEqual(self.client.requests, MockDelugeClient.Requests(torrentFiles: 0))
            expectation.fulfill()
        }
        waitForExpectations(timeout: 0.12)
    }

    func test_autoUpdate_whenAppeared_shouldFire() {
        preferences.set(0.1, for: PreferenceKeys.autoRefreshInterval)
        client.requests.reset()
        viewModel.handle(.appear)
        let expectation = self.expectation(description: "Check")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.11) {
            XCTAssertEqual(self.client.requests, MockDelugeClient.Requests(torrentFiles: 1))
            expectation.fulfill()
        }
        waitForExpectations(timeout: 0.12)
    }

    func test_autoUpdate_whenDisappeared_shouldNotFire() {
        preferences.set(0.1, for: PreferenceKeys.autoRefreshInterval)
        client.requests.reset()
        viewModel.handle(.appear)
        viewModel.handle(.disappear)
        let expectation = self.expectation(description: "Check")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.11) {
            XCTAssertEqual(self.client.requests, MockDelugeClient.Requests(torrentFiles: 0))
            expectation.fulfill()
        }
        waitForExpectations(timeout: 0.12)
    }

    func test_autoUpdate_whenPreferenceDisabled_shouldNotFire() {
        preferences.set(0.1, for: PreferenceKeys.autoRefreshInterval)
        client.requests.reset()
        viewModel.handle(.appear)
        preferences.set(0, for: PreferenceKeys.autoRefreshInterval)
        let expectation = self.expectation(description: "Check")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.11) {
            XCTAssertEqual(self.client.requests, MockDelugeClient.Requests(torrentFiles: 0))
            expectation.fulfill()
        }
        waitForExpectations(timeout: 0.12)
    }

    func test_refresh_whenFails_shouldShowError() {
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

    func test_refresh_isLoading_shouldEmitTrueThenFalse() {
        var values = [Bool]()
        viewModel.state.isLoading.dropFirst().sink {
            values.append($0)
        }.store(in: &observers)
        viewModel.handle(.refresh)
        XCTAssertEqual(values, [true, false])
    }

    func test_sections_shouldHaveHeader() {
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

    func test_sections_shouldHaveInfoRows() {
        let expected: [(String, String)] = [
            ("Size", "0.0 KB"),
            ("Download Speed", "0.0 KB/s"),
            ("Upload Speed", "0.0 KB/s"),
            ("Downloaded", "0.0 KB"),
            ("Uploaded", "0.0 KB"),
            ("ETA", "∞"),
            ("Ratio", "∞"),
            ("Peers", "0 (0)"),
            ("Seeds", "0 (0)"),
        ]

        let expectation = self.expectation(description: "Value received")
        viewModel.state.sections.sink { sections in
            let rows = self.getInfoRows(in: sections[1])
            for (row, expected) in zip(rows, expected) {
                XCTAssertEqual(row.0, expected.0)
                XCTAssertEqual(row.1, expected.1, row.0)
            }
            expectation.fulfill()
        }.store(in: &observers)
        wait(for: [expectation], timeout: 0)
    }

    func test_eta_whenZero_shouldFormatProperly() {
        let expectation = self.expectation(description: "Value received")
        viewModel.state.sections.sink { sections in
            let eta = self.getInfoRows(in: sections[1]).first { $0.0 == "ETA" }!
            XCTAssertEqual(eta.1, "∞")
            expectation.fulfill()
        }.store(in: &observers)
        wait(for: [expectation], timeout: 0)
    }

    func test_ratio_whenInfinite_shouldFormatProperly() {
        subject.send(.mock(uploaded: 1))
        XCTAssertTrue(subject.value.ratio.isInfinite)
        let expectation = self.expectation(description: "Value received")
        viewModel.state.sections.sink { sections in
            let eta = self.getInfoRows(in: sections[1]).first { $0.0 == "Ratio" }!
            XCTAssertEqual(eta.1, "∞")
            expectation.fulfill()
        }.store(in: &observers)
        wait(for: [expectation], timeout: 0)
    }

    func test_ratio_whenNaN_shouldFormatProperly() {
        XCTAssertTrue(subject.value.ratio.isNaN)
        let expectation = self.expectation(description: "Value received")
        viewModel.state.sections.sink { sections in
            let eta = self.getInfoRows(in: sections[1]).first { $0.0 == "Ratio" }!
            XCTAssertEqual(eta.1, "∞")
            expectation.fulfill()
        }.store(in: &observers)
        wait(for: [expectation], timeout: 0)
    }

    func test_sections_shouldHaveTrackers() {
        let trackers = ["udp://tracker.example.com:9000", "http://tracker.example.com:9000/announce"]
        subject.send(.mock(trackers: trackers))

        let expectation = self.expectation(description: "Value received")
        viewModel.state.sections.sink { sections in
            let section = sections[2]
            XCTAssertEqual(section.type, .trackers)

            let inner = section.items.compactMap { item -> String? in
                switch item {
                case let .tracker(tracker):
                    return tracker
                default:
                    XCTFail("Unexpected item")
                    return nil
                }
            }

            XCTAssertEqual(inner, trackers)
            expectation.fulfill()
        }.store(in: &observers)
        wait(for: [expectation], timeout: 0)
    }

    func test_files_shouldBeSorted() {
        let expectation = self.expectation(description: "Value received")
        viewModel.state.sections.sink { sections in
            let section = sections[2]
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

    func test_moreOptions_shouldEmitAlert() {
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

    func test_forceRecheck_shouldPerformRequestAndRefresh() {
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

    func test_forceRecheck_whenFails_shouldEmitAlert() {
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

    func test_pause_shouldPerformRequest() {
        client.requests.reset()
        viewModel.handle(.pause)
        XCTAssertEqual(client.requests, MockDelugeClient.Requests(torrents: 1, pause: 1))
    }

    func test_pause_whenFails_shouldEmitAlert() {
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

    func test_resume_shouldPerformRequest() {
        client.requests.reset()
        viewModel.handle(.resume)
        XCTAssertEqual(client.requests, MockDelugeClient.Requests(torrents: 1, resume: 1))
    }

    func test_resume_whenFails_shouldPerformRequest() {
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

    func test_remove_shouldEmitAlert() {
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

    func test_removeKeepData_shouldPerformRequestAndRefresh() {
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

    func test_removeKeepData_whenFails_shouldEmitAlert() {
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

    func test_removeWithData_shouldPerformRequestAndRefresh() {
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

    func test_removeWithData_whenFails_shouldEmitAlert() {
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
