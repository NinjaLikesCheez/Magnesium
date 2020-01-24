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

    func testHasHeader() {
        let expectation = self.expectation(description: "Value received")
        viewModel.sections
            .sink { sections in
                XCTAssertEqual(sections[0].type, .header)
                expectation.fulfill()
            }
            .store(in: &observers)
        waitForExpectations(timeout: 0)
    }

    private func getInfoRows(in section: TorrentDetailSection) -> [(String, String)] {
        XCTAssertEqual(section.type, .info)
        return section.items.compactMap { item -> (String, String)? in
            switch item {
            case let .info(viewModel):
                let expectation = self.expectation(description: "Value received")
                var value: String!
                viewModel.value
                    .first()
                    .sink(receiveValue: {
                        value = $0
                        expectation.fulfill()
                    })
                    .store(in: &self.observers)
                self.wait(for: [expectation], timeout: 0)
                return (viewModel.name, value)
            default:
                XCTFail("Unexpected item")
                return nil
            }
        }
    }

    func testInfoRows() {
        let expected: [(String, String)] = [
            ("Size", "656.0 MB"),
            ("Download Speed", "1.5 MB/s"),
            ("Upload Speed", "454.3 KB/s"),
            ("Downloaded", "124.5 MB"),
            ("Uploaded", "53.8 MB"),
            ("ETA", "6m 1s"),
            ("Ratio", "0.432"),
            ("Peers", "2 (35)"),
            ("Seeds", "70 (832)"),
        ]

        let expectation = self.expectation(description: "Value received")
        viewModel.sections
            .sink { sections in
                let rows = self.getInfoRows(in: sections[1])
                XCTAssertEqual(rows.map { "\($0.0): \($0.1)" }, expected.map { "\($0.0): \($0.1)" })
                expectation.fulfill()
            }
            .store(in: &observers)
        wait(for: [expectation], timeout: 0)
    }

    func testInfiniteETA() {
        var torrent = subject.value
        torrent.eta = 0
        subject.send(torrent)

        let expectation = self.expectation(description: "Value received")
        viewModel.sections
            .sink { sections in
                let eta = self.getInfoRows(in: sections[1]).first { $0.0 == "ETA" }!
                XCTAssertEqual(eta.1, "∞")
                expectation.fulfill()
            }
            .store(in: &observers)
        wait(for: [expectation], timeout: 0)
    }

    func testInfiniteRatio() {
        var torrent = subject.value
        torrent.downloaded = 0
        subject.send(torrent)

        let expectation = self.expectation(description: "Value received")
        viewModel.sections
            .sink { sections in
                let eta = self.getInfoRows(in: sections[1]).first { $0.0 == "Ratio" }!
                XCTAssertEqual(eta.1, "∞")
                expectation.fulfill()
            }
            .store(in: &observers)
        wait(for: [expectation], timeout: 0)
    }

    func testTrackers() {
        let expected = ["udp://tracker.archlinux.org:6969", "http://tracker.archlinux.org:6969/announce"]

        let expectation = self.expectation(description: "Value received")
        viewModel.sections
            .sink { sections in
                let section = sections[2]
                XCTAssertEqual(section.type, .trackers)

                let trackers = section.items.compactMap { item -> String? in
                    switch item {
                    case let .tracker(tracker):
                        return tracker
                    default:
                        XCTFail("Unexpected item")
                        return nil
                    }
                }

                XCTAssertEqual(trackers, expected)
                expectation.fulfill()
            }
            .store(in: &observers)
        wait(for: [expectation], timeout: 0)
    }

    func testFilesSorted() {
        let expectation = self.expectation(description: "Value received")
        viewModel.sections
            .sink { sections in
                let section = sections[3]
                XCTAssertEqual(section.type, .files)

                let files = section.items.compactMap { item -> String? in
                    switch item {
                    case let .file(viewModel):
                        return viewModel.name
                    default:
                        XCTFail("Unexpected item")
                        return nil
                    }
                }
                XCTAssertEqual(files, ["file.r00", "file.r01", "file.rar"])
                expectation.fulfill()
            }
            .store(in: &observers)
        waitForExpectations(timeout: 0)
    }
}

// swiftlint:disable:next static_operator
private func == (lhs: (String, String), rhs: (String, String)) -> Bool {
    return lhs.0 == rhs.0 && lhs.1 == rhs.1
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
