//
//  DefaultNavigatorTests.swift
//  NavigatorTests
//
//  Created by James Hurst on 2020-01-12.
//

@testable import Navigator
import UIKit
import XCTest

class DefaultNavigatorTests: XCTestCase {
    private let window = UIWindow()
    private var navigationController: UINavigationController!
    private var navigator: DefaultNavigator!

    override func setUp() {
        super.setUp()
        navigationController = UINavigationController(rootViewController: UIViewController())
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        navigator = DefaultNavigator(viewController: navigationController)
        RunLoop.current.run(until: Date())
    }

    func testPush() {
        navigator.push(UIViewController(), animated: false)
        XCTAssertEqual(navigationController.viewControllers.count, 2)
    }

    func testPop() {
        navigator.push(UIViewController(), animated: false)
        navigator.pop(animated: false)
        XCTAssertEqual(navigationController.viewControllers.count, 1)
    }

    func testPresent() {
        navigator.present(UIViewController(), animated: false)
        XCTAssertNotNil(navigationController.presentedViewController)
    }

    func testDismiss() {
        let viewController = DismissTestViewController()
        navigator.present(viewController, animated: false)
        navigator.dismiss(animated: false)
        // The implementation of UIViewController.dismiss won't work in tests since the presented view controller's
        // `isBeingPresented` property gets stuck as true.
        XCTAssertTrue(viewController.wasDismissCalled)
    }

    func testRootViewControllerNotDismissed() {
        let viewController = DismissTestViewController()
        navigator = DefaultNavigator(viewController: viewController)
        navigator.dismiss(animated: false)
        XCTAssertEqual(navigator.presentationStack.items.count, 1)
        XCTAssertFalse(viewController.wasDismissCalled)
    }

    func testCompactShowDetail() {
        window.rootViewController = UIViewController()
        let splitViewController = SplitViewController(horizontalSizeClass: .compact)
        splitViewController.viewControllers = [navigationController]
        window.rootViewController = splitViewController
        navigator.showDetail(UIViewController())
        XCTAssertEqual(navigationController.viewControllers.count, 2)
    }

    func testRegularShowDetail() {
        window.rootViewController = UIViewController()
        let splitViewController = SplitViewController(horizontalSizeClass: .regular)
        splitViewController.viewControllers = [navigationController]
        window.rootViewController = splitViewController
        navigator.showDetail(UIViewController())
        XCTAssertEqual(splitViewController.viewControllers.count, 2)
    }

    func testCompactPopDetail() {
        window.rootViewController = UIViewController()
        let splitViewController = SplitViewController(horizontalSizeClass: .compact)
        splitViewController.viewControllers = [navigationController]
        window.rootViewController = splitViewController
        let detailNavigator = navigator.showDetail(UINavigationController(rootViewController: UIViewController()))
        detailNavigator?.popNestedDetail(animated: false)
        XCTAssertEqual(navigationController.viewControllers.count, 1)
    }

    func testRegularPopDetailDoesNothing() {
        window.rootViewController = UIViewController()
        let splitViewController = SplitViewController(horizontalSizeClass: .regular)
        splitViewController.viewControllers = [navigationController]
        window.rootViewController = splitViewController
        let detailNavigator = navigator.showDetail(UINavigationController())
        detailNavigator?.popNestedDetail(animated: false)
        XCTAssertEqual(splitViewController.viewControllers.count, 2)
    }
}

extension UIViewController: Navigatable {
    public func viewController() -> UIViewController? {
        return self
    }
}

private final class SplitViewController: UISplitViewController {
    let horizontalSizeClass: UIUserInterfaceSizeClass

    init(horizontalSizeClass: UIUserInterfaceSizeClass) {
        self.horizontalSizeClass = horizontalSizeClass
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var traitCollection: UITraitCollection {
        return UITraitCollection(traitsFrom: [
            super.traitCollection,
            UITraitCollection(horizontalSizeClass: horizontalSizeClass),
        ])
    }
}

private final class DismissTestViewController: UIViewController {
    var wasDismissCalled = false

    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        wasDismissCalled = true
    }
}
