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
    private let client = MockDelugeClient()
    private let preferences = MockPreferences()
    private var viewModel: DelugeTorrentListViewModel!
    private var observers = [AnyCancellable]()

    override func setUp() {
        super.setUp()
        viewModel = DelugeTorrentListViewModel(client: client, preferences: preferences)
    }

    func test_autoUpdate_shouldFire() {
        client.requests.reset()
        preferences.set(1, for: PreferenceKeys.autoRefreshInterval)
        let expectation = self.expectation(description: "Check")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            XCTAssertEqual(self.client.requests, MockDelugeClient.Requests(torrents: 1))
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.2)
    }

    func test_autoUpdate_whenPreferenceDisabled_shouldNotFire() {
        client.requests.reset()
        preferences.set(1, for: PreferenceKeys.autoRefreshInterval)
        preferences.set(0, for: PreferenceKeys.autoRefreshInterval)
        let expectation = self.expectation(description: "Check")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            XCTAssertEqual(self.client.requests, MockDelugeClient.Requests(torrents: 0))
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.2)
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

    func test_add_shouldEmitAddEvent() {
        var event: TorrentListEvent?
        viewModel.events.first().sink { event = $0 }.store(in: &observers)
        viewModel.handle(.add(source: .view(UIView(), rect: .zero)))
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

    func test_selectItem_shouldEmitDetailEvent() {
        var event: TorrentListEvent!
        viewModel.events.first().sink { event = $0 }.store(in: &observers)
        viewModel.handle(.selectItem(index: 0))
        guard case .detail = event else {
            XCTFail("Unexpected event: \(String(describing: event))")
            return
        }
    }
}
