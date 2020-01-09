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
        let splitNavigator = SplitNavigator()
        let viewModel = MockTorrentListViewModel(navigator: splitNavigator.master)

        let expectation = self.expectation(description: "Navigation")
        let observer = viewModel.torrentsUpdated.sink { _ in
            defer {
                expectation.fulfill()
            }

            viewModel.didSelectItem(at: 0)

            XCTAssertEqual(splitNavigator.detail.presentationStack.count, 1)
            XCTAssertEqual(splitNavigator.detail.presentationStack[0].screens.count, 1)

            let firstScreen = splitNavigator.detail.presentationStack[0].screens[0]
            guard let navigationScreen = firstScreen as? NavigationControllerScreen else {
                XCTFail("Expected NavigationControllerScreen, instead got \(type(of: firstScreen))")
                return
            }

            guard case Screens.Torrents.detail = navigationScreen.builder(splitNavigator.detail)! else {
                let screen = navigationScreen.builder(splitNavigator.detail)!
                XCTFail("Expected Screens.Torrents.detail, instead got \(type(of: screen))")
                return
            }
        }

        waitForExpectations(timeout: 1)
    }
}
