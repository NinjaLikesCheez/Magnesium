//
//  DelugeTorrentDetailViewModelTests.swift
//  MagnesiumTests
//
//  Created by James Hurst on 2020-01-22.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import Coordinator
@testable import Magnesium
import Preferences
import XCTest

final class DelugeTorrentDetailViewModelTests: XCTestCase {
    private let coordinator = MockCoordinator()
    private let subject = CurrentValueSubject<DelugeTorrent, Never>(DelugeTorrent.mock())
    private let client = MockDelugeClient()
    private let preferences = MockPreferences()
    private var viewModel: TorrentDetailViewModel!
    private var observers = [AnyCancellable]()

    override func setUp() {
        super.setUp()
        viewModel = DelugeTorrentDetailViewModel(
            torrentSubject: subject,
            client: client,
            preferences: preferences,
            refresher: MockRefreshable()
        )
        viewModel.coordinator = coordinator
    }

    func testNoAutoUpdateIfNotDidAppear() throws {
        preferences.set(1, for: PreferenceKeys.autoRefreshInterval)
        client.requests.reset()
        let expectation = self.expectation(description: "Update")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            XCTAssertEqual(self.client.requests, MockDelugeClient.Requests(torrentFiles: 0))
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2)
    }

    func testAutoUpdate() throws {
        preferences.set(1, for: PreferenceKeys.autoRefreshInterval)
        client.requests.reset()
        viewModel.didAppear()

        let firstCheck = expectation(description: "First check")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            XCTAssertEqual(self.client.requests, MockDelugeClient.Requests(torrentFiles: 1))
            firstCheck.fulfill()
        }
        waitForExpectations(timeout: 2)

        viewModel.didDisappear()

        let secondCheck = expectation(description: "Second check")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            XCTAssertEqual(self.client.requests, MockDelugeClient.Requests(torrentFiles: 1))
            secondCheck.fulfill()
        }
        waitForExpectations(timeout: 2)
    }

    func testAutoUpdateStopsWhenDisabled() throws {
        preferences.set(1, for: PreferenceKeys.autoRefreshInterval)
        client.requests.reset()
        viewModel.didAppear()

        let firstCheck = expectation(description: "First check")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            XCTAssertEqual(self.client.requests, MockDelugeClient.Requests(torrentFiles: 1))
            firstCheck.fulfill()
        }
        waitForExpectations(timeout: 2)

        preferences.set(0, for: PreferenceKeys.autoRefreshInterval)

        let secondCheck = expectation(description: "Second check")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            XCTAssertEqual(self.client.requests, MockDelugeClient.Requests(torrentFiles: 1))
            secondCheck.fulfill()
        }
        waitForExpectations(timeout: 2)
    }

    func testRefreshShowsError() {
        client.errors.torrentFiles = true
        XCTAssertNil(coordinator.alert)
        viewModel.refresh().sink(receiveCompletion: { _ in }, receiveValue: { _ in }).store(in: &observers)
        XCTAssertEqual(coordinator.alert?.title, "Update Failed")
    }
}

private final class MockRefreshable: DelugeRefreshable {
    func refreshTorrents() -> AnyPublisher<Void, DelugeError> {
        return Just(()).setFailureType(to: DelugeError.self).eraseToAnyPublisher()
    }
}

private final class MockCoordinator: TorrentDetailCoordinator {
    private final class MockPresentable: Presentable {
        let didDismiss: AnyPublisher<Void, Never> = Empty().eraseToAnyPublisher()
    }

    let presentationViewController = UIViewController()
    var childCoordinators = [Coordinator]()
    var childCoordinatorObservers = [AnyCancellable]()
    var alert: Alert?

    func start() -> Presentable {
        return MockPresentable()
    }

    func showAlert(_ alert: Alert, from source: PopoverSource?) {
        self.alert = alert
    }
}
