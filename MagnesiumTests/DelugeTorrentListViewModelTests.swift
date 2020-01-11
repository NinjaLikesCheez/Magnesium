//
//  DelugeTorrentListViewModelTests.swift
//  MagnesiumTests
//
//  Created by James Hurst on 2019-12-20.
//  Copyright © 2019 James Hurst. All rights reserved.
//

import Combine
@testable import Magnesium
import XCTest

final class DelugeTorrentListViewModelTests: XCTestCase {
    func testSelectionNavigatesToDetail() {
        let navigator = MockNavigator()
        let viewModel = DelugeTorrentListViewModel(client: MockDelugeClient())
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
}

private final class MockDelugeClient: DelugeClient {
    func authenticate() -> AnyPublisher<Never, DelugeClientError> {
        XCTFail()
        return Empty(completeImmediately: true).eraseToAnyPublisher()
    }

    func getTorrents() -> AnyPublisher<[DelugeTorrent], DelugeClientError> {
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

private final class MockNavigator: Navigator {
    var detail: Navigatable?

    func push(_ navigatable: Navigatable, animated: Bool) {
        fatalError()
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

    func dismissDetailOrReplace(with navigatable: Navigatable, animated: Bool) {
        XCTFail()
    }
}
