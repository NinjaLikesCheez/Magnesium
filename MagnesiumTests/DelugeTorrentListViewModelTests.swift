//
//  DelugeTorrentListViewModelTests.swift
//  MagnesiumTests
//
//  Created by James Hurst on 2019-12-20.
//  Copyright © 2019 James Hurst. All rights reserved.
//

import Combine
@testable import Magnesium
import Preferences
import XCTest

final class DelugeTorrentListViewModelTests: XCTestCase {
    private let preferences: Preferences = MockPreferences()

    override func setUp() {
        super.setUp()
        _ = try? preferences.registerDefault(1, for: PreferenceKeys.autoRefreshInterval)
    }

    func testSelectionNavigatesToDetail() {
        let coordinator = MockCoordinator()
        let viewModel = DelugeTorrentListViewModel(
            coordinator: coordinator,
            client: MockDelugeClient(),
            preferences: preferences
        )
        viewModel.didSelectItem(at: 0)
        XCTAssertTrue(coordinator.wasShowTorrentDetailCalled)
    }

    func testAutoUpdate() {
        let coordinator = MockCoordinator()
        let client = MockDelugeClient()
        let viewModel = DelugeTorrentListViewModel(
            coordinator: coordinator,
            client: client,
            preferences: preferences
        )
        _ = viewModel
        client.resetRequests()

        let expectation = self.expectation(description: "Update")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            XCTAssertEqual(client.requests, MockDelugeClient.Requests(torrents: 1))
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2)
    }

    func testAutoUpdateStopsWhenDisabled() throws {
        let coordinator = MockCoordinator()
        let client = MockDelugeClient()
        let viewModel = DelugeTorrentListViewModel(
            coordinator: coordinator,
            client: client,
            preferences: preferences
        )
        _ = viewModel
        client.resetRequests()

        let firstCheck = expectation(description: "First check")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            XCTAssertEqual(client.requests, MockDelugeClient.Requests(torrents: 1))
            firstCheck.fulfill()
        }

        waitForExpectations(timeout: 2)

        try preferences.set(0, for: PreferenceKeys.autoRefreshInterval)

        let secondCheck = expectation(description: "Second check")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            XCTAssertEqual(client.requests, MockDelugeClient.Requests(torrents: 1))
            secondCheck.fulfill()
        }

        waitForExpectations(timeout: 2)
    }
}

private final class MockCoordinator: TorrentListCoordinator {
    private final class MockPresentable: Presentable {
        let didDismiss: AnyPublisher<Never, Never> = Empty().eraseToAnyPublisher()
    }

    let presentationViewController = UIViewController()
    private(set) var wasShowTorrentDetailCalled = false
    var childCoordinators: [Coordinator] = []
    var childCoordinatorObservers: [AnyCancellable] = []

    func start() -> Presentable { return MockPresentable() }
    func showSettings() {}
    func showTorrentDetail(_ viewModel: TorrentDetailViewModel) {
        wasShowTorrentDetailCalled = true
    }
}

private final class MockDelugeClient: DelugeClient {
    struct Requests: Equatable {
        var torrents = 0
    }

    private(set) var requests = Requests()

    func resetRequests() {
        requests = Requests()
    }

    func authenticate() -> AnyPublisher<Never, DelugeError> {
        return Empty(completeImmediately: true).eraseToAnyPublisher()
    }

    func getTorrents() -> AnyPublisher<[DelugeTorrent], DelugeError> {
        requests.torrents += 1

        let torrents = [
            DelugeTorrent(
                hash: "",
                name: "",
                state: .seeding,
                dateAdded: Date(),
                downloadRate: 0,
                uploadRate: 0,
                eta: 0,
                progress: 1,
                downloaded: 0,
                uploaded: 0,
                size: 0,
                seeds: 0,
                totalSeeds: 0,
                peers: 0,
                totalPeers: 0,
                trackers: [],
                label: ""
            ),
        ]
        return Just(torrents)
            .setFailureType(to: DelugeError.self)
            .eraseToAnyPublisher()
    }

    func getLabels() -> AnyPublisher<[String], DelugeError> {
        return Just([]).setFailureType(to: DelugeError.self).eraseToAnyPublisher()
    }

    func getTorrentFiles(hash: String) -> AnyPublisher<[DelugeTorrentFile], DelugeError> {
        return Just([]).setFailureType(to: DelugeError.self).eraseToAnyPublisher()
    }

    func pause(hashes: [String]) -> AnyPublisher<Never, DelugeError> {
        return Empty(completeImmediately: true).eraseToAnyPublisher()
    }

    func resume(hashes: [String]) -> AnyPublisher<Never, DelugeError> {
        return Empty(completeImmediately: true).eraseToAnyPublisher()
    }

    func remove(hashes: [String], removeData: Bool) -> AnyPublisher<Never, DelugeError> {
        return Empty(completeImmediately: true).eraseToAnyPublisher()
    }

    func recheck(hashes: [String]) -> AnyPublisher<Never, DelugeError> {
        return Empty(completeImmediately: true).eraseToAnyPublisher()
    }
}
