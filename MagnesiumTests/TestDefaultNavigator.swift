//
//  TestDefaultNavigator.swift
//  MagnesiumTests
//
//  Created by James Hurst on 2019-12-20.
//  Copyright © 2019 James Hurst. All rights reserved.
//

@testable import Magnesium
import XCTest

final class DefaultNavigatorTests: XCTestCase {
    func testPushReusesNavigator() {
        let viewController = UIViewController()
        let navigationController = UINavigationController(rootViewController: viewController)
        let navigator = DefaultNavigator(presentationContext: PresentationContext(viewController: navigationController))
        let viewModel = MockViewModel()
        navigator.push(viewModel, animated: true)
        XCTAssertNotNil(viewModel.navigator)
        XCTAssertTrue(navigator === viewModel.navigator as? DefaultNavigator)
    }

    func testPresentCreatesNewNavigator() {
        let viewController = UIViewController()
        let navigator = DefaultNavigator(presentationContext: PresentationContext(viewController: viewController))
        let viewModel = MockViewModel()
        navigator.present(viewModel, animated: true)
        XCTAssertNotNil(viewModel.navigator)
        XCTAssertTrue(navigator !== viewModel.navigator as? DefaultNavigator)
    }

    func testShowDetailCreatesNewNavigator() {
        let splitViewController = UISplitViewController()
        let viewController = UIViewController()
        splitViewController.viewControllers = [viewController]
        let navigator = DefaultNavigator(presentationContext: PresentationContext(viewController: viewController))
        let viewModel = MockViewModel()
        navigator.showDetail(viewModel)
        XCTAssertNotNil(viewModel.navigator)
        XCTAssertTrue(navigator !== viewModel.navigator as? DefaultNavigator)
    }
}

private final class MockViewModel: NavigatorConfigurable, Navigatable {
    var navigator: Navigator?

    func viewController() -> UIViewController? {
        return UIViewController()
    }
}
