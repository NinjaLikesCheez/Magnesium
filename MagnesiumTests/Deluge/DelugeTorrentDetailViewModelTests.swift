//
//  DelugeTorrentDetailViewModelTests.swift
//  MagnesiumTests
//
//  Created by James Hurst on 2020-01-22.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
@testable import Magnesium
import XCTest

final class DelugeTorrentDetailViewModelTests: XCTestCase {
    typealias Implementation = DelugeTorrentDetailViewModelImplementation

    private let torrent = CurrentValueSubject<DelugeTorrent, Never>(.mock())
    private let labels = CurrentValueSubject<[DelugeLabel], Never>([.mock()])
    private let client = MockDelugeClient()
    private let preferences = MockPreferences()
    private lazy var implementation = Implementation(
        client: client,
        refresher: MockDelugeRefresher(client: client)
    )
    private var viewModel: StandardTorrentDetailViewModel<Implementation>!
    private var observers = [AnyCancellable]()

    override func setUp() {
        super.setUp()
        viewModel = StandardTorrentDetailViewModel(
            implementation: implementation,
            torrent: torrent,
            labels: labels,
            preferences: preferences
        )
    }

    func test_pause_shouldPerformRequest() {
        client.requests.reset()
        viewModel.handle(.pause)
        XCTAssertEqual(client.requests, MockDelugeClient.Requests(currentState: 1, pause: 1))
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
        XCTAssertEqual(client.requests, MockDelugeClient.Requests(pause: 1))
    }

    func test_resume_shouldPerformRequest() {
        client.requests.reset()
        viewModel.handle(.resume)
        XCTAssertEqual(client.requests, MockDelugeClient.Requests(currentState: 1, resume: 1))
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
        XCTAssertEqual(client.requests, MockDelugeClient.Requests(resume: 1))
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
        XCTAssertEqual(client.requests, MockDelugeClient.Requests(currentState: 1, remove: [false]))

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
        XCTAssertEqual(client.requests, MockDelugeClient.Requests(remove: [false]))
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
        XCTAssertEqual(client.requests, MockDelugeClient.Requests(currentState: 1, remove: [true]))
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
        XCTAssertEqual(client.requests, MockDelugeClient.Requests(remove: [true]))
    }

    func test_verify_shouldPerformRequestAndRefresh() {
        client.requests.reset()
        viewModel.verify()
        XCTAssertEqual(client.requests, MockDelugeClient.Requests(currentState: 1, recheck: 1))
    }

    func test_verify_whenFails_shouldEmitAlert() {
        client.errors.recheck = true
        client.requests.reset()

        var errorAlert: Alert?
        viewModel.events.first().sink {
            guard case let .alert(inner, source: _) = $0 else {
                XCTFail("Unexpected event")
                return
            }
            errorAlert = inner
        }.store(in: &observers)
        viewModel.verify()
        XCTAssertEqual(errorAlert?.title, "Failed to Verify Files")
        XCTAssertEqual(client.requests, MockDelugeClient.Requests(recheck: 1))
    }

    func test_updateTrackers_shouldPerformRequestAndRefresh() {
        client.requests.reset()
        viewModel.updateTrackers()
        XCTAssertEqual(client.requests, MockDelugeClient.Requests(currentState: 1, reannounce: 1))
    }

    func test_updateTrackers_whenFails_shouldEmitAlert() {
        client.errors.reannounce = true
        client.requests.reset()

        var errorAlert: Alert?
        viewModel.events.first().sink {
            guard case let .alert(inner, source: _) = $0 else {
                XCTFail("Unexpected event")
                return
            }
            errorAlert = inner
        }.store(in: &observers)
        viewModel.updateTrackers()
        XCTAssertEqual(errorAlert?.title, "Failed to Update Trackers")
        XCTAssertEqual(client.requests, MockDelugeClient.Requests(reannounce: 1))
    }

    // MARK: presentLabelSelection

    func test_presentLabelSelection_shouldEmitSelectionAlert() {
        labels.send([.mock(), .mock(name: "test")])
        var alert: Alert?
        viewModel.events.first().sink {
            guard case let .alert(inner, source: _) = $0 else {
                XCTFail("Unexpected event")
                return
            }
            alert = inner
        }.store(in: &observers)
        viewModel.presentLabelSelection(from: .view(UIView(), rect: .zero))
        XCTAssertEqual(alert?.actions.map { $0.title }, ["None", "test", "Cancel"])
    }

    func test_presentLabelSelection_whenOptionSelected_shouldPerformRequestAndRefresh() {
        client.requests.reset()
        labels.send([.mock(), .mock(name: "test")])
        var alert: Alert?
        viewModel.events.first().sink {
            guard case let .alert(inner, source: _) = $0 else {
                XCTFail("Unexpected event")
                return
            }
            alert = inner
        }.store(in: &observers)
        viewModel.presentLabelSelection(from: .view(UIView(), rect: .zero))
        alert?.actions.first { $0.title == "test" }?.handler?()
        XCTAssertEqual(client.requests, MockDelugeClient.Requests(currentState: 1, setLabel: 1))
    }

    func test_presentLabelSelection_whenOptionSelected_andRequestFails_shouldPerformRequestAndRefresh() {
        client.requests.reset()
        client.errors.setLabel = true
        labels.send([.mock(), .mock(name: "test")])

        var labelsAlert: Alert?
        viewModel.events.first().sink {
            guard case let .alert(inner, source: _) = $0 else {
                XCTFail("Unexpected event")
                return
            }
            labelsAlert = inner
        }.store(in: &observers)
        viewModel.presentLabelSelection(from: .view(UIView(), rect: .zero))

        var errorAlert: Alert?
        viewModel.events.first().sink {
            guard case let .alert(inner, source: _) = $0 else {
                XCTFail("Unexpected event")
                return
            }
            errorAlert = inner
        }.store(in: &observers)
        labelsAlert?.actions.first { $0.title == "test" }?.handler?()
        XCTAssertEqual(errorAlert?.title, "Failed to Set Label")
        XCTAssertEqual(client.requests, MockDelugeClient.Requests(setLabel: 1))
    }

    // MARK: autoRefresh

    func test_autoRefresh_whenNotAppeared_shouldNotFire() {
        preferences.set(0.5, for: PreferenceKeys.autoRefreshInterval)
        client.requests.reset()
        let expectation = self.expectation(description: "Check")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertEqual(self.client.requests, MockDelugeClient.Requests(torrentFiles: 0))
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func test_autoRefresh_whenAppeared_shouldFire() {
        preferences.set(0.5, for: PreferenceKeys.autoRefreshInterval)
        client.requests.reset()
        viewModel.handle(.appear)
        let expectation = self.expectation(description: "Check")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertEqual(self.client.requests, MockDelugeClient.Requests(torrentFiles: 1))
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func test_autoRefresh_whenDisappeared_shouldNotFire() {
        preferences.set(0.5, for: PreferenceKeys.autoRefreshInterval)
        client.requests.reset()
        viewModel.handle(.appear)
        viewModel.handle(.disappear)
        let expectation = self.expectation(description: "Check")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertEqual(self.client.requests, MockDelugeClient.Requests(torrentFiles: 0))
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func test_autoRefresh_whenPreferenceDisabled_shouldNotFire() {
        preferences.set(0.5, for: PreferenceKeys.autoRefreshInterval)
        client.requests.reset()
        viewModel.handle(.appear)
        preferences.set(0, for: PreferenceKeys.autoRefreshInterval)
        let expectation = self.expectation(description: "Check")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertEqual(self.client.requests, MockDelugeClient.Requests(torrentFiles: 0))
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    // MARK: refresh

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

    // MARK: sections

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

    func test_sections_shouldHaveTrackers() {
        let trackers = ["udp://tracker.example.com:9000", "http://tracker.example.com:9000/announce"]
        torrent.send(.mock(trackers: trackers))

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

    func test_sections_files_shouldBeSorted() {
        let expectation = self.expectation(description: "Value received")
        viewModel.state.sections.sink { sections in
            let section = sections[2]
            XCTAssertEqual(section.type, .files)

            let files = section.items.compactMap { item -> String? in
                switch item {
                case let .file(viewModel):
                    var value: String?
                    viewModel.state.name.sink { value = $0 }.store(in: &self.observers)
                    return value
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

    // MARK: eta

    func test_eta_whenZero_shouldFormatProperly() {
        let expectation = self.expectation(description: "Value received")
        viewModel.state.sections.sink { sections in
            let eta = self.getInfoRows(in: sections[1]).first { $0.0 == "ETA" }!
            XCTAssertEqual(eta.1, "∞")
            expectation.fulfill()
        }.store(in: &observers)
        wait(for: [expectation], timeout: 0)
    }

    // MARK: ratio

    func test_ratio_whenInfinite_shouldFormatProperly() {
        torrent.send(.mock(uploaded: 1))
        XCTAssertTrue(torrent.value.ratio.isInfinite)
        let expectation = self.expectation(description: "Value received")
        viewModel.state.sections.sink { sections in
            let eta = self.getInfoRows(in: sections[1]).first { $0.0 == "Ratio" }!
            XCTAssertEqual(eta.1, "∞")
            expectation.fulfill()
        }.store(in: &observers)
        wait(for: [expectation], timeout: 0)
    }

    func test_ratio_whenNaN_shouldFormatProperly() {
        XCTAssertTrue(torrent.value.ratio.isNaN)
        let expectation = self.expectation(description: "Value received")
        viewModel.state.sections.sink { sections in
            let eta = self.getInfoRows(in: sections[1]).first { $0.0 == "Ratio" }!
            XCTAssertEqual(eta.1, "∞")
            expectation.fulfill()
        }.store(in: &observers)
        wait(for: [expectation], timeout: 0)
    }

    // MARK: moreOptions

    func test_moreOptions_shouldEmitActivities() {
        torrent.send(.mock(name: "Mock"))
        var event: TorrentDetailEvent?
        viewModel.events.sink { event = $0 }.store(in: &observers)
        viewModel.handle(.moreOptions(source: .view(UIView(), rect: .zero)))
        guard case let .activities(activities, metadata, _) = event else {
            XCTFail("Unexpected event: \(String(describing: event))")
            return
        }
        XCTAssertEqual(activities.map { $0.activityTitle }, ["Set Label", "Verify Files", "Update Trackers"])
        XCTAssertEqual(metadata.title, "Mock")
    }
}

// swiftlint:disable:next static_operator
private func == (lhs: (String, String), rhs: (String, String)) -> Bool {
    return lhs.0 == rhs.0 && lhs.1 == rhs.1
}
