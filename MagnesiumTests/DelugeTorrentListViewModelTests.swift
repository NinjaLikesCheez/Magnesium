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
    func testSelectionNavigatesToDetail() {
        let coordinator = MockCoordinator()
        let viewModel = DelugeTorrentListViewModel(
            coordinator: coordinator,
            client: MockDelugeClient(),
            preferences: MockPreferences()
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
            preferences: MockPreferences()
        )
        _ = viewModel
        client.resetRequests()

        let expectation = self.expectation(description: "Update")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            XCTAssertEqual(client.requests, MockDelugeClient.Requests(torrents: 1, labels: 1))
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2)
    }
}

private final class MockCoordinator: TorrentListCoordinator {
    let didComplete: AnyPublisher<Never, Never> = Empty().eraseToAnyPublisher()
    private(set) var wasShowTorrentDetailCalled = false
    var childCoordinators: [Coordinator] = []
    var childCoordinatorObservers: [AnyCancellable] = []

    func start() {}
    func showListForSelectedServer() {}
    func showSettings() {}
    func showTorrentDetail(_ viewModel: TorrentDetailViewModel) {
        wasShowTorrentDetailCalled = true
    }
}

private final class MockDelugeClient: DelugeClient {
    struct Requests: Equatable {
        var torrents = 0
        var labels = 0
    }

    private(set) var requests = Requests()

    func resetRequests() {
        requests = Requests()
    }

    func authenticate() -> AnyPublisher<Never, DelugeClientError> {
        XCTFail()
        return Empty(completeImmediately: true).eraseToAnyPublisher()
    }

    func getTorrents() -> AnyPublisher<[DelugeTorrent], DelugeClientError> {
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
            .setFailureType(to: DelugeClientError.self)
            .eraseToAnyPublisher()
    }

    func getLabels() -> AnyPublisher<[String], DelugeClientError> {
        requests.labels += 1
        return Just([]).setFailureType(to: DelugeClientError.self).eraseToAnyPublisher()
    }

    func getTorrentFiles(hash: String) -> AnyPublisher<[DelugeTorrentFile], DelugeClientError> {
        return Just([]).setFailureType(to: DelugeClientError.self).eraseToAnyPublisher()
    }

    func pause(hashes: [String]) -> AnyPublisher<Never, DelugeClientError> {
        XCTFail()
        return Empty(completeImmediately: true).eraseToAnyPublisher()
    }

    func resume(hashes: [String]) -> AnyPublisher<Never, DelugeClientError> {
        XCTFail()
        return Empty(completeImmediately: true).eraseToAnyPublisher()
    }

    func remove(hashes: [String], removeData: Bool) -> AnyPublisher<Never, DelugeClientError> {
        XCTFail()
        return Empty(completeImmediately: true).eraseToAnyPublisher()
    }

    func recheck(hashes: [String]) -> AnyPublisher<Never, DelugeClientError> {
        XCTFail()
        return Empty(completeImmediately: true).eraseToAnyPublisher()
    }
}

private final class MockPreferences: Preferences {
    var valueUpdated: AnyPublisher<(AnyPreferenceKey, Any?), Never> {
        return Empty().eraseToAnyPublisher()
    }

    func registerDefault<T>(_ value: T, for key: PreferenceKey<T>) throws {}

    func value<T>(for key: PreferenceKey<T>) -> T? {
        if key.value == PreferenceKeys.autoRefreshInterval.value {
            return TimeInterval(1) as? T
        }

        return nil
    }

    func set<T>(_ value: T, for key: PreferenceKey<T>) {}
    func containsValue<T>(for key: PreferenceKey<T>) -> Bool { return false }
    func removeValue<T>(for key: PreferenceKey<T>) {}
}
