//
//  DelugeTorrentListViewModelTests.swift
//  MagnesiumTests
//
//  Created by James Hurst on 2019-12-20.
//  Copyright © 2019 James Hurst. All rights reserved.
//

import Combine
@testable import Magnesium
import Navigator
import XCTest

final class DelugeTorrentListViewModelTests: XCTestCase {
    func testSelectionNavigatesToDetail() {
        let navigator = MockDetailNavigator()
        let viewModel = DelugeTorrentListViewModel(client: MockDelugeClient(), preferences: MockPreferenceManager())
        viewModel.navigator = navigator
        viewModel.didSelectItem(at: 0)

        XCTAssertNotNil(navigator.detail)

        let detail = navigator.detail
        guard let navigationScreen = detail as? NavigationControllerScreen else {
            XCTFail("Expected NavigationControllerScreen, instead got \(type(of: detail))")
            return
        }

        guard case Screens.Torrents.detail = navigationScreen.root else {
            XCTFail("Expected Screens.Torrents.detail, instead got \(type(of: navigationScreen.root))")
            return
        }
    }

    func testAutoUpdate() {
        let client = MockDelugeClient()
        let viewModel = DelugeTorrentListViewModel(client: client, preferences: MockPreferenceManager())
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

private final class MockPreferenceManager: PreferenceManager {
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

private final class MockDetailNavigator: Navigator {
    var detail: Navigatable?

    func push(_ navigatable: Navigatable, animated: Bool) {
        XCTFail()
    }

    func pop(animated: Bool) {
        XCTFail()
    }

    func present(
        _ navigatable: Navigatable,
        style: PresentationStyle,
        animated: Bool,
        completion: (() -> Void)?
    ) -> Navigator? {
        XCTFail()
        return nil
    }

    func dismiss(animated: Bool, completion: (() -> Void)?) {
        XCTFail()
    }

    func showDetail(_ navigatable: Navigatable) -> Navigator? {
        detail = navigatable
        return nil
    }

    func popNestedDetail(animated: Bool) -> Bool {
        XCTFail()
        return false
    }
}
