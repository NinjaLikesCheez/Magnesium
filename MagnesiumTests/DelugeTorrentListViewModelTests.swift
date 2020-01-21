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
    private let preferences: Preferences = MockPreferences()
    private var observers = [AnyCancellable]()

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
        _ = try? preferences.registerDefault(1, for: PreferenceKeys.autoRefreshInterval)

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
        _ = try? preferences.registerDefault(1, for: PreferenceKeys.autoRefreshInterval)

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

    func testRefreshShowsError() {
        let coordinator = MockCoordinator()
        let client = MockDelugeClient()
        let viewModel = DelugeTorrentListViewModel(
            coordinator: coordinator,
            client: client,
            preferences: preferences
        )
        _ = viewModel
        client.throwError = true
        XCTAssertTrue(coordinator.alert == nil)
        viewModel.refresh().sink(receiveCompletion: { _ in }, receiveValue: { _ in }).store(in: &observers)
        XCTAssertEqual(coordinator.alert?.message, DelugeError.unauthenticated.errorDescription)
    }
}

private final class MockCoordinator: TorrentListCoordinator {
    private final class MockPresentable: Presentable {
        let didDismiss: AnyPublisher<Never, Never> = Empty().eraseToAnyPublisher()
    }

    let presentationViewController = UIViewController()
    var wasShowTorrentDetailCalled = false
    var alert: Alert?
    var childCoordinators: [Coordinator] = []
    var childCoordinatorObservers: [AnyCancellable] = []

    func start() -> Presentable { return MockPresentable() }
    func showSettings() {}

    func showTorrentDetail(_ viewModel: TorrentDetailViewModel) {
        wasShowTorrentDetailCalled = true
    }

    func showAlert(_ alert: Alert, from source: PopoverSource? = nil) {
        self.alert = alert
    }
}

private final class MockDelugeClient: DelugeClient {
    struct Requests: Equatable {
        var torrents = 0
    }

    private(set) var requests = Requests()
    var throwError = false

    func resetRequests() {
        requests = Requests()
    }

    func authenticate() -> AnyPublisher<Never, DelugeError> {
        return Empty(completeImmediately: true).eraseToAnyPublisher()
    }

    func fetchTorrents() -> AnyPublisher<[DelugeTorrent], DelugeError> {
        guard !throwError else {
            return Fail(error: DelugeError.unauthenticated).eraseToAnyPublisher()
        }

        requests.torrents += 1
        return Just([DelugeTorrent.mock()])
            .setFailureType(to: DelugeError.self)
            .eraseToAnyPublisher()
    }

    func fetchLabels() -> AnyPublisher<[String], DelugeError> {
        return Just([]).setFailureType(to: DelugeError.self).eraseToAnyPublisher()
    }

    func fetchTorrentFiles(hash: String) -> AnyPublisher<[DelugeTorrentFile], DelugeError> {
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
