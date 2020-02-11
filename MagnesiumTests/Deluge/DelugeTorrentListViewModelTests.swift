//
//  DelugeTorrentListViewModelTests.swift
//  MagnesiumTests
//
//  Created by James Hurst on 2019-12-20.
//  Copyright © 2019 James Hurst. All rights reserved.
//

import Combine
@testable import Magnesium
import XCTest

final class DelugeTorrentListViewModelTests: XCTestCase {
    typealias Implementation = DelugeTorrentListViewModelImplementation

    private let client = MockDelugeClient()
    private let preferences = MockPreferences()
    private lazy var implementation = Implementation(client: client, preferences: preferences)
    private var viewModel: StandardTorrentListViewModel<Implementation>!
    private var observers = [AnyCancellable]()

    override func setUp() {
        super.setUp()
        viewModel = StandardTorrentListViewModel(implementation: implementation, preferences: preferences)
    }

    func test_pause_shouldPauseAndRefresh() {
        client.requests.reset()
        viewModel.pause(.mock())
        XCTAssertEqual(client.requests, MockDelugeClient.Requests(currentState: 1, pause: 1))
    }

    func test_pause_whenFails_shouldEmitAlert() {
        client.requests.reset()
        client.errors.pause = true

        var alert: Alert?
        viewModel.events.first().sink {
            guard case let .alert(inner, source: _) = $0 else {
                XCTFail("Unexpected event")
                return
            }
            alert = inner
        }.store(in: &observers)

        viewModel.pause(.mock(name: "Torrent"))
        XCTAssertEqual(alert?.title, "Failed to Pause \"Torrent\"")
        XCTAssertEqual(client.requests, MockDelugeClient.Requests(pause: 1))
    }

    func test_resume_shouldResumeAndRefresh() {
        client.requests.reset()
        viewModel.resume(.mock(name: "Torrent"))
        XCTAssertEqual(client.requests, MockDelugeClient.Requests(currentState: 1, resume: 1))
    }

    func test_resume_whenFails_shouldEmitAlert() {
        client.requests.reset()
        client.errors.resume = true

        var alert: Alert?
        viewModel.events.first().sink {
            guard case let .alert(inner, source: _) = $0 else {
                XCTFail("Unexpected event")
                return
            }
            alert = inner
        }.store(in: &observers)

        viewModel.resume(.mock(name: "Torrent"))
        XCTAssertEqual(alert?.title, "Failed to Resume \"Torrent\"")
        XCTAssertEqual(client.requests, MockDelugeClient.Requests(resume: 1))
    }

    func test_presentRemoveOptions_shouldEmitAlert() {
        client.requests.reset()
        var alert: Alert?
        viewModel.events.first().sink {
            guard case let .alert(inner, source: _) = $0 else {
                XCTFail("Unexpected event")
                return
            }
            alert = inner
        }.store(in: &observers)
        viewModel.presentRemoveOptions(for: .mock(name: "Mock"), from: .view(UIView(), rect: .zero))
        XCTAssertEqual(alert?.title, "Remove")
        XCTAssertEqual(alert?.message, "Mock")
        XCTAssertEqual(alert?.actions.map { $0.title }, ["Keep Data", "Remove Data", "Cancel"])
    }

    func test_presentRemoveOptions_whenRemoveDataSelected_shouldRemoveAndRefresh() {
        client.requests.reset()
        var alert: Alert?
        viewModel.events.first().sink {
            guard case let .alert(inner, source: _) = $0 else {
                XCTFail("Unexpected event")
                return
            }
            alert = inner
        }.store(in: &observers)
        viewModel.presentRemoveOptions(for: .mock(name: "Mock"), from: .view(UIView(), rect: .zero))
        alert?.actions.first { $0.title == "Remove Data" }?.handler?()
        XCTAssertEqual(client.requests, MockDelugeClient.Requests(currentState: 1, remove: [true]))
    }

    func test_presentRemoveOptions_whenRemoveDataSelected_whenFails_shouldEmitAlert() {
        client.requests.reset()
        client.errors.removeWithData = true

        var optionsAlert: Alert?
        viewModel.events.first().sink {
            guard case let .alert(inner, source: _) = $0 else {
                XCTFail("Unexpected event")
                return
            }
            optionsAlert = inner
        }.store(in: &observers)
        viewModel.presentRemoveOptions(for: .mock(name: "Mock"), from: .view(UIView(), rect: .zero))

        var errorAlert: Alert?
        viewModel.events.first().sink {
            guard case let .alert(inner, source: _) = $0 else {
                XCTFail("Unexpected event")
                return
            }
            errorAlert = inner
        }.store(in: &observers)
        optionsAlert?.actions.first { $0.title == "Remove Data" }?.handler?()
        XCTAssertEqual(errorAlert?.title, "Failed to Remove \"Mock\"")
        XCTAssertEqual(client.requests, MockDelugeClient.Requests(remove: [true]))
    }

    func test_presentRemoveOptions_whenKeepDataSelected_shouldRemoveAndRefresh() {
        client.requests.reset()
        var alert: Alert?
        viewModel.events.first().sink {
            guard case let .alert(inner, source: _) = $0 else {
                XCTFail("Unexpected event")
                return
            }
            alert = inner
        }.store(in: &observers)
        viewModel.presentRemoveOptions(for: .mock(name: "Mock"), from: .view(UIView(), rect: .zero))
        alert?.actions.first { $0.title == "Keep Data" }?.handler?()
        XCTAssertEqual(client.requests, MockDelugeClient.Requests(currentState: 1, remove: [false]))
    }

    func test_presentRemoveOptions_whenKeepDataSelected_whenFails_shouldEmitAlert() {
        client.requests.reset()
        client.errors.removeKeepData = true

        var optionsAlert: Alert?
        viewModel.events.first().sink {
            guard case let .alert(inner, source: _) = $0 else {
                XCTFail("Unexpected event")
                return
            }
            optionsAlert = inner
        }.store(in: &observers)
        viewModel.presentRemoveOptions(for: .mock(name: "Mock"), from: .view(UIView(), rect: .zero))

        var errorAlert: Alert?
        viewModel.events.first().sink {
            guard case let .alert(inner, source: _) = $0 else {
                XCTFail("Unexpected event")
                return
            }
            errorAlert = inner
        }.store(in: &observers)
        optionsAlert?.actions.first { $0.title == "Keep Data" }?.handler?()
        XCTAssertEqual(errorAlert?.title, "Failed to Remove \"Mock\"")
        XCTAssertEqual(client.requests, MockDelugeClient.Requests(remove: [false]))
    }

    func test_verify_shouldRecheckAndRefresh() {
        client.requests.reset()
        viewModel.verify(.mock())
        XCTAssertEqual(client.requests, MockDelugeClient.Requests(currentState: 1, recheck: 1))
    }

    func test_verify_whenFails_shouldEmitAlert() {
        client.requests.reset()
        client.errors.recheck = true

        var alert: Alert?
        viewModel.events.first().sink {
            guard case let .alert(inner, source: _) = $0 else {
                XCTFail("Unexpected event")
                return
            }
            alert = inner
        }.store(in: &observers)

        viewModel.verify(.mock(name: "Torrent"))
        XCTAssertEqual(alert?.title, "Failed to Verify Files for \"Torrent\"")
        XCTAssertEqual(client.requests, MockDelugeClient.Requests(recheck: 1))
    }

    func test_updateTrackers_shouldPerformRequestAndRefresh() {
        client.requests.reset()
        viewModel.updateTrackers(for: .mock())
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
        viewModel.updateTrackers(for: .mock(name: "Mock"))
        XCTAssertEqual(errorAlert?.title, "Failed to Update Trackers for \"Mock\"")
        XCTAssertEqual(client.requests, MockDelugeClient.Requests(reannounce: 1))
    }

    // MARK: presentLabelSelection

    func test_presentLabelSelection_shouldEmitSelectionAlert() {
        client.labels = [.mock(), .mock(name: "test")]
        viewModel.handle(.refresh)

        var alert: Alert?
        viewModel.events.first().sink {
            guard case let .alert(inner, source: _) = $0 else {
                XCTFail("Unexpected event")
                return
            }
            alert = inner
        }.store(in: &observers)
        viewModel.presentLabelSelection(for: .mock(name: "Mock"), from: .view(UIView(), rect: .zero))
        XCTAssertEqual(alert?.title, "Set Label")
        XCTAssertEqual(alert?.message, "Mock")
        XCTAssertEqual(alert?.actions.map { $0.title }, ["None", "test", "Cancel"])
    }

    func test_presentLabelSelection_whenOptionSelected_shouldPerformRequestAndRefresh() {
        client.labels = [.mock(), .mock(name: "test")]
        viewModel.handle(.refresh)
        client.requests.reset()

        var alert: Alert?
        viewModel.events.first().sink {
            guard case let .alert(inner, source: _) = $0 else {
                XCTFail("Unexpected event")
                return
            }
            alert = inner
        }.store(in: &observers)
        viewModel.presentLabelSelection(for: .mock(), from: .view(UIView(), rect: .zero))
        alert?.actions.first { $0.title == "test" }?.handler?()
        XCTAssertEqual(client.requests, MockDelugeClient.Requests(currentState: 1, setLabel: 1))
    }

    func test_presentLabelSelection_whenOptionSelected_andRequestFails_shouldPerformRequestAndRefresh() {
        client.labels = [.mock(), .mock(name: "test")]
        viewModel.handle(.refresh)
        client.requests.reset()
        client.errors.setLabel = true

        var labelsAlert: Alert?
        viewModel.events.first().sink {
            guard case let .alert(inner, source: _) = $0 else {
                XCTFail("Unexpected event")
                return
            }
            labelsAlert = inner
        }.store(in: &observers)
        viewModel.presentLabelSelection(for: .mock(name: "Mock"), from: .view(UIView(), rect: .zero))

        var errorAlert: Alert?
        viewModel.events.first().sink {
            guard case let .alert(inner, source: _) = $0 else {
                XCTFail("Unexpected event")
                return
            }
            errorAlert = inner
        }.store(in: &observers)
        labelsAlert?.actions.first { $0.title == "test" }?.handler?()
        XCTAssertEqual(errorAlert?.title, "Failed to Set Label for \"Mock\"")
        XCTAssertEqual(client.requests, MockDelugeClient.Requests(setLabel: 1))
    }

    // MARK: presentActivities

    func test_moreOptions_shouldEmitActivities() {
        var event: TorrentListEvent?
        viewModel.events.sink { event = $0 }.store(in: &observers)
        viewModel.presentActivities(for: .mock(name: "Mock"), source: .view(UIView(), rect: .zero), complete: { _ in })
        guard case let .activities(activities, metadata, _) = event else {
            XCTFail("Unexpected event: \(String(describing: event))")
            return
        }
        XCTAssertEqual(activities.map { $0.activityTitle }, ["Set Label", "Verify Files", "Update Trackers"])
        XCTAssertEqual(metadata.title, "Mock")
    }

    // MARK: autoRefresh

    func test_autoRefresh_shouldFire() {
        client.requests.reset()
        preferences.set(0.5, for: PreferenceKeys.autoRefreshInterval)
        let expectation = self.expectation(description: "Check")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertEqual(self.client.requests, MockDelugeClient.Requests(currentState: 1))
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func test_autoRefresh_whenPreferenceDisabled_shouldNotFire() {
        client.requests.reset()
        preferences.set(0.5, for: PreferenceKeys.autoRefreshInterval)
        preferences.set(0, for: PreferenceKeys.autoRefreshInterval)
        let expectation = self.expectation(description: "Check")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertEqual(self.client.requests, MockDelugeClient.Requests(currentState: 0))
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    // MARK: addLink

    func test_addLink_withInvalidInput_shouldEmitAlert() {
        var alert: Alert?
        viewModel.events.first().sink {
            guard case let .alert(inner, source: _) = $0 else {
                XCTFail("Unexpected event")
                return
            }
            alert = inner
        }.store(in: &observers)
        viewModel.addLink("^")
        XCTAssertEqual(alert?.message, "That link doesn't appear to be valid.")
    }

    func test_addLink_withMagnetLink_shouldPerformAddMagnetURLRequest() {
        client.requests.reset()
        let url = "magnet:?"
        viewModel.addLink(url)
        XCTAssertEqual(client.requests, MockDelugeClient.Requests(addMagnetURL: 1))
    }

    func test_addLink_withWebLink_shouldPerformAddURLRequest() {
        client.requests.reset()
        let url = "https://example.com"
        viewModel.addLink(url)
        XCTAssertEqual(client.requests, MockDelugeClient.Requests(addURL: 1))
    }

    func test_addLink_whenFails_shouldEmitAlert() {
        client.errors.addURL = true
        var alert: Alert?
        viewModel.events.first().sink {
            guard case let .alert(inner, source: _) = $0 else {
                XCTFail("Unexpected event")
                return
            }
            alert = inner
        }.store(in: &observers)
        viewModel.addLink("https://example.com")
        XCTAssertEqual(alert?.title, "Failed to Add Torrent")
    }

    // MARK: items

    func test_items_shouldEmitInitialValue() {
        let expectation = self.expectation(description: "Value received")
        viewModel.state.items.first().sink { _ in
            expectation.fulfill()
        }.store(in: &observers)
        waitForExpectations(timeout: 0)
    }

    func test_items_shouldRemoveDuplicates() {
        client.requests.reset()
        var count = 0
        viewModel.state.items.dropFirst().sink { _ in
            count += 1
        }.store(in: &observers)
        viewModel.handle(.refresh)
        XCTAssertEqual(client.requests.currentState, 1)
        XCTAssertEqual(count, 0)
    }

    func test_items_shouldEmitNewValues() {
        client.requests.reset()
        var count = 0
        viewModel.state.items.dropFirst().sink { _ in
            count += 1
        }.store(in: &observers)
        client.torrents.append(.randomMock())
        viewModel.handle(.refresh)
        XCTAssertEqual(client.requests.currentState, 1)
        XCTAssertEqual(count, 1)
    }

    // MARK: hasActiveFilters

    func test_hasActiveFilters_withNoFilters_shouldBeFalse() {
        var value: Bool?
        viewModel.state.hasActiveFilters.sink { value = $0 }.store(in: &observers)
        XCTAssertFalse(value!)
    }

    func test_hasActiveFilters_withFilters_shouldBeTrue() {
        var value: Bool?
        viewModel.state.hasActiveFilters.dropFirst().sink { value = $0 }.store(in: &observers)
        preferences.set(FilterOptions(state: .downloading), for: PreferenceKeys.filterOptions)
        XCTAssertTrue(value!)
    }

    // MARK: handle

    func test_refresh_whenFails_shouldShowError() {
        client.errors.currentState = true
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

    func test_addSelected_shouldEmitAddEvent() {
        var event: TorrentListEvent?
        viewModel.events.first().sink { event = $0 }.store(in: &observers)
        viewModel.handle(.addSelected(source: .view(UIView(), rect: .zero)))
        guard case .add = event else {
            XCTFail("Unexpected event: \(String(describing: event))")
            return
        }
    }

    func test_filterSelected_shouldEmitFilterEvent() {
        var event: TorrentListEvent?
        viewModel.events.sink {
            event = $0
        }.store(in: &observers)
        viewModel.handle(.filterSelected(source: .view(UIView(), rect: .zero)))
        guard case .filter = event else {
            XCTFail("Unexpected event")
            return
        }
    }

    func test_settingsSelected_shouldEmitSettingsEvent() {
        var event: TorrentListEvent?
        viewModel.events.sink {
            event = $0
        }.store(in: &observers)
        viewModel.handle(.settingsSelected)
        guard case .settings = event else {
            XCTFail("Unexpected event")
            return
        }
    }

    func test_selectItem_shouldEmitDetailEvent() {
        var event: TorrentListEvent?
        viewModel.events.sink { event = $0 }.store(in: &observers)
        viewModel.handle(.itemSelected(index: 0))
        guard case .detail = event else {
            XCTFail("Unexpected event: \(String(describing: event))")
            return
        }
    }

    func test_search_shouldUpdateItems() {
        client.torrents = [
            .mock(hash: "A", name: "test torrent", dateAdded: Date(timeIntervalSinceNow: 0)),
            .mock(hash: "B", name: "example", dateAdded: Date(timeIntervalSinceNow: -1)),
            .mock(hash: "C", name: "TEST.TORRENT", dateAdded: Date(timeIntervalSinceNow: -2)),
        ]
        viewModel.handle(.refresh)
        var items: [AnyTorrentListItemViewModel]?
        viewModel.state.items.sink { items = $0 }.store(in: &observers)
        viewModel.handle(.search(query: "test tor"))
        XCTAssertEqual(items!.count, 2)
        let names: [String?] = items?.map {
            var name: String?
            $0.state.name.sink { name = $0 }.store(in: &observers)
            return name
        } ?? []
        XCTAssertEqual(names, ["test torrent", "TEST.TORRENT"])
    }

    // MARK: DelugeRefreshable

    func test_refreshDeluge_shouldRefreshTorrents() {
        client.requests.reset()
        client.torrents.append(.randomMock())

        let expectation = self.expectation(description: "Value received")
        viewModel.state.items.dropFirst().sink { _ in
            expectation.fulfill()
        }.store(in: &observers)

        implementation.refreshDeluge()
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &observers)

        waitForExpectations(timeout: 0)
        XCTAssertEqual(client.requests, MockDelugeClient.Requests(currentState: 1))
    }

    // MARK: TorrentListProvider

    func test_detailViewModelForItem_shouldReturnExpectedViewModel() {
        typealias Implementation = DelugeTorrentDetailViewModelImplementation // swiftlint:disable:this nesting
        let detailViewModel = viewModel.detailViewModelForItem(at: 0)!.base as AnyObject
        guard type(of: detailViewModel) === StandardTorrentDetailViewModel<Implementation>.self else {
            XCTFail("Unexpected view model: \(String(describing: viewModel))")
            return
        }
    }

    func test_contextMenuForItem_withActiveTorrent_shouldReturnExpectedMenu() {
        client.labels = [.mock(), .mock(name: "test")]
        viewModel.handle(.refresh)

        let menu = viewModel.contextMenuForItem(at: 0)!
        func menuString(_ menu: UIMenuElement, level: Int = 0) -> String {
            var output = String(repeating: " ", count: level * 2)
            output += "\(menu.title)\n"
            if let menu = menu as? UIMenu {
                output += menu.children
                    .map { menuString($0, level: level + 1) }
                    .joined()
            }
            return output
        }
        // swiftformat:disable all
        let expected = """

              Pause
              Set Label
                None
                test
              Verify Files
              Update Trackers
              Remove
                Keep Data
                Remove Data

            """
        // swiftformat:enable all
        XCTAssertEqual(menuString(menu), expected)
    }

    func test_contextMenuForItem_withInactiveTorrent_shouldReturnExpectedMenu() {
        client.torrents = [.mock(state: .paused)]
        client.labels = [.mock(), .mock(name: "test")]
        viewModel.handle(.refresh)

        let menu = viewModel.contextMenuForItem(at: 0)!
        func menuString(_ menu: UIMenuElement, level: Int = 0) -> String {
            var output = String(repeating: " ", count: level * 2)
            output += "\(menu.title)\n"
            if let menu = menu as? UIMenu {
                output += menu.children
                    .map { menuString($0, level: level + 1) }
                    .joined()
            }
            return output
        }
        // swiftformat:disable all
        let expected = """

              Resume
              Set Label
                None
                test
              Verify Files
              Update Trackers
              Remove
                Keep Data
                Remove Data

            """
        // swiftformat:enable all
        XCTAssertEqual(menuString(menu), expected)
    }

    func test_leadingSwipeActionsConfiguration_whenTorrentIsActive_shouldReturnedExpectedConfiguration() {
        let configuration = viewModel.leadingSwipeActionsConfigurationForItem(
            at: 0,
            source: .view(UIView(), rect: .zero)
        )
        XCTAssertEqual(configuration?.actions.map { $0.image }, [UIImage(systemName: "pause.fill")])
    }

    func test_leadingSwipeActionsConfiguration_whenTorrentIsInactive_shouldReturnedExpectedConfiguration() {
        client.torrents = [.mock(state: .paused)]
        viewModel.handle(.refresh)

        let configuration = viewModel.leadingSwipeActionsConfigurationForItem(
            at: 0,
            source: .view(UIView(), rect: .zero)
        )
        XCTAssertEqual(configuration?.actions.map { $0.image }, [UIImage(systemName: "play.fill")])
    }

    func test_trailingSwipeActionsConfiguration_shouldReturnExpectedConfiguration() {
        let configuration = viewModel.trailingSwipeActionsConfigurationForItem(
            at: 0,
            source: .view(UIView(), rect: .zero)
        )
        let expected = [UIImage(systemName: "trash.fill"), UIImage(systemName: "ellipsis.circle.fill")]
        XCTAssertEqual(configuration?.actions.map { $0.image }, expected)
    }
}
