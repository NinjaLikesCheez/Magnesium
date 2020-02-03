//
//  TransmissionTorrentListViewModelTests.swift
//  MagnesiumTests
//
//  Created by James Hurst on 2020-02-01.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import Coordinator
@testable import Magnesium
import Preferences
import XCTest

final class TransmissionTorrentListViewModelTests: XCTestCase {
    private let client = MockTransmissionClient()
    private let preferences = MockPreferences()
    private var viewModel: TransmissionTorrentListViewModel!
    private var observers = [AnyCancellable]()

    override func setUp() {
        super.setUp()
        viewModel = TransmissionTorrentListViewModel(client: client, preferences: preferences)
    }

    func test_autoRefresh_shouldFire() {
        client.requests.reset()
        preferences.set(0.1, for: PreferenceKeys.autoRefreshInterval)
        let expectation = self.expectation(description: "Check")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            XCTAssertEqual(self.client.requests, MockTransmissionClient.Requests(torrents: 1))
            expectation.fulfill()
        }
        waitForExpectations(timeout: 0.14)
    }

    func test_autoRefresh_whenPreferenceDisabled_shouldNotFire() {
        client.requests.reset()
        preferences.set(0.1, for: PreferenceKeys.autoRefreshInterval)
        preferences.set(0, for: PreferenceKeys.autoRefreshInterval)
        let expectation = self.expectation(description: "Check")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            XCTAssertEqual(self.client.requests, MockTransmissionClient.Requests(torrents: 0))
            expectation.fulfill()
        }
        waitForExpectations(timeout: 0.14)
    }

    func test_refresh_whenFails_shouldShowError() {
        client.errors.torrents = true
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

    func test_add_shouldEmitAddEvent() {
        var event: TorrentListEvent?
        viewModel.events.first().sink { event = $0 }.store(in: &observers)
        viewModel.handle(.addSelected(source: .view(UIView(), rect: .zero)))
        guard case .add = event else {
            XCTFail("Unexpected event: \(String(describing: event))")
            return
        }
    }

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

    func test_addLink_withMagnetLink_shouldPerformAddURLRequest() {
        client.requests.reset()
        let url = "magnet:?"
        viewModel.addLink(url)
        XCTAssertEqual(client.requests, MockTransmissionClient.Requests(addURL: 1))
    }

    func test_addLink_withWebLink_shouldPerformAddURLRequest() {
        client.requests.reset()
        let url = "https://example.com"
        viewModel.addLink(url)
        XCTAssertEqual(client.requests, MockTransmissionClient.Requests(addURL: 1))
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

    func test_selectItem_shouldEmitDetailEvent() {
        var event: TorrentListEvent!
        viewModel.events.first().sink { event = $0 }.store(in: &observers)
        viewModel.handle(.itemSelected(index: 0))
        guard case .detail = event else {
            XCTFail("Unexpected event: \(String(describing: event))")
            return
        }
    }

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
        XCTAssertEqual(client.requests.torrents, 1)
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
        XCTAssertEqual(client.requests.torrents, 1)
        XCTAssertEqual(count, 1)
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

    func test_refreshTransmission_shouldRefreshTorrents() {
        client.requests.reset()
        viewModel.refreshTransmission().sink(receiveCompletion: { _ in }, receiveValue: { _ in }).store(in: &observers)
        XCTAssertEqual(client.requests, MockTransmissionClient.Requests(torrents: 1))
    }
}
