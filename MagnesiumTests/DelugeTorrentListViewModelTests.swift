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
    private let coordinator = MockCoordinator()
    private let client = MockDelugeClient()
    private let preferences = MockPreferences()
    private var viewModel: TorrentListViewModel!
    private var observers = [AnyCancellable]()

    override func setUp() {
        super.setUp()
        viewModel = DelugeTorrentListViewModel(
            coordinator: coordinator,
            client: client,
            preferences: preferences
        )
    }

    func testAutoUpdate() throws {
        preferences.set(1, for: PreferenceKeys.autoRefreshInterval)
        client.requests.reset()
        let expectation = self.expectation(description: "Update")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            XCTAssertEqual(self.client.requests, MockDelugeClient.Requests(torrents: 1))
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2)
    }

    func testAutoUpdateStopsWhenDisabled() throws {
        preferences.set(1, for: PreferenceKeys.autoRefreshInterval)
        client.requests.reset()

        let firstCheck = expectation(description: "First check")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            XCTAssertEqual(self.client.requests, MockDelugeClient.Requests(torrents: 1))
            firstCheck.fulfill()
        }
        waitForExpectations(timeout: 2)

        preferences.set(0, for: PreferenceKeys.autoRefreshInterval)

        let secondCheck = expectation(description: "Second check")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            XCTAssertEqual(self.client.requests, MockDelugeClient.Requests(torrents: 1))
            secondCheck.fulfill()
        }
        waitForExpectations(timeout: 2)
    }

    func testRefreshShowsError() {
        client.errors.torrents = true
        XCTAssertNil(coordinator.alert)
        viewModel.refresh().sink(receiveCompletion: { _ in }, receiveValue: { _ in }).store(in: &observers)
        XCTAssertEqual(coordinator.alert?.title, "Update Failed")
    }

    func testAddShowsSelection() {
        XCTAssertNil(coordinator.alert)
        viewModel.didSelectAdd()
        XCTAssertEqual(coordinator.alert?.title, "Add Torrent")
    }

    func testAddLinkURLValidation() {
        let url = "^"
        XCTAssertNil(coordinator.alert)
        viewModel.addLink(url)
        XCTAssertEqual(coordinator.alert?.message, "That link doesn't appear to be valid.")
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

    func testAddShowsError() {
        client.errors.addURL = true
        let url = "https://example.com"
        XCTAssertNil(coordinator.alert)
        viewModel.addLink(url)
        XCTAssertEqual(coordinator.alert?.title, "Failed to Add Torrent")
    }

    func testSelectionNavigatesToDetail() {
        viewModel.didSelectItem(at: 0)
        XCTAssertTrue(coordinator.wasShowTorrentDetailCalled)
    }
}

private final class MockCoordinator: TorrentListCoordinator {
    private final class MockPresentable: Presentable {
        let didDismiss: AnyPublisher<Void, Never> = Empty().eraseToAnyPublisher()
    }

    let presentationViewController = UIViewController()
    var childCoordinators = [Coordinator]()
    var childCoordinatorObservers = [AnyCancellable]()
    var wasShowAddLinkCalled = false
    var wasShowTorrentDetailCalled = false
    var alert: Alert?

    func start() -> Presentable {
        return MockPresentable()
    }

    func showTorrentDetail(_ viewModel: TorrentDetailViewModel) {
        wasShowTorrentDetailCalled = true
    }

    func showSettings() {
        // noop
    }

    func showAddLink() -> AnyPublisher<String, Never> {
        wasShowAddLinkCalled = true
        return Empty(completeImmediately: true).eraseToAnyPublisher()
    }

    func showAlert(_ alert: Alert, from source: PopoverSource? = nil) {
        self.alert = alert
    }
}
