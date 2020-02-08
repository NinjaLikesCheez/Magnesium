//
//  DelugeTorrentListViewModelTests.swift
//  MagnesiumTests
//
//  Created by James Hurst on 2019-12-20.
//  Copyright © 2019 James Hurst. All rights reserved.
//

import Combine
import Coordinator
@testable import Magnesium
import Preferences
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

    // MARK: TorrentListPreviewProvider

    func test_detailViewModelForItem_shouldReturnExpectedViewModel() {
        typealias Implementation = DelugeTorrentDetailViewModelImplementation // swiftlint:disable:this nesting
        let detailViewModel = viewModel.detailViewModelForItem(at: 0)!.base as AnyObject
        guard type(of: detailViewModel) === StandardTorrentDetailViewModel<Implementation>.self else {
            XCTFail("Unexpected view model: \(String(describing: viewModel))")
            return
        }
    }

    func test_contextMenuForItem_shouldReturnExpectedMenu() {
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

              Set Label
                None
                test
              Pause
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

              Set Label
                None
                test
              Resume
              Remove
                Keep Data
                Remove Data

            """
        // swiftformat:enable all
        XCTAssertEqual(menuString(menu), expected)
    }

    func test_handleSetLabelAction_shouldSetLabelAndRefresh() {
        client.requests.reset()
        viewModel.handleSetLabelAction(for: .mock(), label: .mock())
        XCTAssertEqual(client.requests, MockDelugeClient.Requests(currentState: 1, setLabel: 1))
    }

    func test_handleSetLabelAction_whenFails_shouldEmitAlert() {
        client.requests.reset()
        client.errors.setLabel = true

        var alert: Alert?
        viewModel.events.first().sink {
            guard case let .alert(inner, source: _) = $0 else {
                XCTFail("Unexpected event")
                return
            }
            alert = inner
        }.store(in: &observers)

        viewModel.handleSetLabelAction(for: .mock(name: "Torrent"), label: .mock())
        XCTAssertEqual(alert?.title, "Failed to Set Label for \"Torrent\"")
        XCTAssertEqual(client.requests, MockDelugeClient.Requests(setLabel: 1))
    }

    func test_handlePauseAction_shouldPauseAndRefresh() {
        client.requests.reset()
        viewModel.handlePauseAction(for: .mock())
        XCTAssertEqual(client.requests, MockDelugeClient.Requests(currentState: 1, pause: 1))
    }

    func test_handlePauseAction_whenFails_shouldEmitAlert() {
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

        viewModel.handlePauseAction(for: .mock(name: "Torrent"))
        XCTAssertEqual(alert?.title, "Failed to Pause \"Torrent\"")
        XCTAssertEqual(client.requests, MockDelugeClient.Requests(pause: 1))
    }

    func test_handleResumeAction_shouldResumeAndRefresh() {
        client.requests.reset()
        viewModel.handleResumeAction(for: .mock(name: "Torrent"))
        XCTAssertEqual(client.requests, MockDelugeClient.Requests(currentState: 1, resume: 1))
    }

    func test_handleResumeAction_whenFails_shouldEmitAlert() {
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

        viewModel.handleResumeAction(for: .mock(name: "Torrent"))
        XCTAssertEqual(alert?.title, "Failed to Resume \"Torrent\"")
        XCTAssertEqual(client.requests, MockDelugeClient.Requests(resume: 1))
    }

    func test_handleRemoveAction_withRemoveData_shouldRemoveAndRefresh() {
        client.requests.reset()
        viewModel.handleRemoveAction(for: .mock(name: "Torrent"), removeData: true)
        XCTAssertEqual(client.requests, MockDelugeClient.Requests(currentState: 1, remove: [true]))
    }

    func test_handleRemoveAction_withRemoveData_whenFails_shouldEmitAlert() {
        client.requests.reset()
        client.errors.removeWithData = true

        var alert: Alert?
        viewModel.events.first().sink {
            guard case let .alert(inner, source: _) = $0 else {
                XCTFail("Unexpected event")
                return
            }
            alert = inner
        }.store(in: &observers)

        viewModel.handleRemoveAction(for: .mock(name: "Torrent"), removeData: true)
        XCTAssertEqual(alert?.title, "Failed to Remove \"Torrent\"")
        XCTAssertEqual(client.requests, MockDelugeClient.Requests(remove: [true]))
    }

    func test_handleRemoveAction_withKeepData_shouldRemoveAndRefresh() {
        client.requests.reset()
        viewModel.handleRemoveAction(for: .mock(name: "Torrent"), removeData: false)
        XCTAssertEqual(client.requests, MockDelugeClient.Requests(currentState: 1, remove: [false]))
    }

    func test_handleRemoveAction_withKeepData_whenFails_shouldEmitAlert() {
        client.requests.reset()
        client.errors.removeKeepData = true

        var alert: Alert?
        viewModel.events.first().sink {
            guard case let .alert(inner, source: _) = $0 else {
                XCTFail("Unexpected event")
                return
            }
            alert = inner
        }.store(in: &observers)

        viewModel.handleRemoveAction(for: .mock(name: "Torrent"), removeData: false)
        XCTAssertEqual(alert?.title, "Failed to Remove \"Torrent\"")
        XCTAssertEqual(client.requests, MockDelugeClient.Requests(remove: [false]))
    }
}
