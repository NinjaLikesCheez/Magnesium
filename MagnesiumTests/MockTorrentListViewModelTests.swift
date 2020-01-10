//
//  MockTorrentListViewModelTests.swift
//  MagnesiumTests
//
//  Created by James Hurst on 2019-12-20.
//  Copyright © 2019 James Hurst. All rights reserved.
//

@testable import Magnesium
import XCTest

final class MockTorrentListViewModelTests: XCTestCase {
    func testSelectionNavigatesToDetail() {
        let navigator = MockNavigator()
        let viewModel = MockTorrentListViewModel(navigator: navigator)

        let expectation = self.expectation(description: "Navigation")
        let observer = viewModel.torrentsUpdated.sink { _ in
            defer {
                expectation.fulfill()
            }

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

        waitForExpectations(timeout: 1)
    }
}

private final class MockNavigator: Navigator {
    var detail: Navigatable?

    func push(_ navigatable: Navigatable, animated: Bool) {}
    func pop(animated: Bool) {}
    func popToRoot(animated: Bool) {}

    func present(
        _ navigatable: Navigatable,
        style: PresentationStyle,
        animated: Bool,
        completion: (() -> Void)?
    ) -> Navigator? {
        return nil
    }

    func dismiss(animated: Bool, completion: (() -> Void)?) {
        completion?()
    }

    func showDetail(_ navigatable: Navigatable) -> Navigator? {
        detail = navigatable
        return nil
    }
}
