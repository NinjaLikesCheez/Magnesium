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
    private var viewModel: TorrentListViewModel!
    private var observers = [AnyCancellable]()

    override func setUp() {
        super.setUp()
        viewModel = DelugeTorrentListViewModel(client: client, preferences: preferences)
    }

    func testAutoUpdate() throws {
        preferences.set(1, for: PreferenceKeys.autoRefreshInterval)
        client.requests.reset()
        let expectation = self.expectation(description: "Update")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            XCTAssertEqual(self.client.requests, MockDelugeClient.Requests(torrents: 1))
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.2)
    }

    func testAutoUpdateStopsWhenDisabled() throws {
        preferences.set(1, for: PreferenceKeys.autoRefreshInterval)
        client.requests.reset()

        let firstCheck = expectation(description: "First check")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            XCTAssertEqual(self.client.requests, MockDelugeClient.Requests(torrents: 1))
            firstCheck.fulfill()
        }
        waitForExpectations(timeout: 1.2)

        preferences.set(0, for: PreferenceKeys.autoRefreshInterval)

        let secondCheck = expectation(description: "Second check")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            XCTAssertEqual(self.client.requests, MockDelugeClient.Requests(torrents: 1))
            secondCheck.fulfill()
        }
        waitForExpectations(timeout: 1.2)
    }

    func testRefreshError() {
        client.errors.torrents = true

        var alert: Alert?
        viewModel.events.first().sink {
            guard case let .alert(inner, source: _) = $0 else {
                XCTFail("Unexpected event")
                return
            }
            alert = inner
        }.store(in: &observers)

        viewModel.refresh().sink(receiveCompletion: { _ in }, receiveValue: { _ in }).store(in: &observers)
        XCTAssertEqual(alert?.title, "Update Failed")
    }

    func testAdd() {
        var event: TorrentListEvent?
        viewModel.events
            .first()
            .sink { event = $0 }
            .store(in: &observers)
        viewModel.didSelectAdd(from: .view(UIView(), rect: .zero))
        guard case .add = event else {
            XCTFail("Unexpected event: \(String(describing: event))")
            return
        }
    }

    func testAddLinkURLValidation() {
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

    func testAddMagnetLink() {
        client.requests.reset()
        let url = "magnet:?"
        viewModel.addLink(url)
        XCTAssertEqual(client.requests, MockDelugeClient.Requests(addMagnetURL: 1))
    }

    func testAddTorrentLink() {
        client.requests.reset()
        let url = "https://example.com"
        viewModel.addLink(url)
        XCTAssertEqual(client.requests, MockDelugeClient.Requests(addURL: 1))
    }

    func testAddError() {
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

    func testSelectionNavigatesToDetail() {
        var event: TorrentListEvent!
        viewModel.events
            .first()
            .sink { event = $0 }
            .store(in: &observers)
        viewModel.didSelectItem(at: 0)
        guard case .detail = event else {
            XCTFail("Unexpected event: \(String(describing: event))")
            return
        }
    }
}
