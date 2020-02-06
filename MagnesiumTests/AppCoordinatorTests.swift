//
//  AppCoordinatorTests.swift
//  MagnesiumTests
//
//  Created by James Hurst on 2020-02-03.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import Coordinator
@testable import Magnesium
import ViewModel
import XCTest

class AppCoordinatorTests: XCTestCase {
    private let window = UIWindow()
    private let preferences = MockPreferences()
    private lazy var session = Session(preferences: preferences)
    private let splitViewController = MockSplitViewController()
    private var coordinator: AppCoordinator!

    override func setUp() {
        super.setUp()
        coordinator = AppCoordinator(
            window: window,
            preferences: preferences,
            session: session,
            splitViewController: splitViewController
        )
    }

    func test_presentable_shouldBeSplitViewController() {
        XCTAssertEqual(splitViewController, coordinator.presentable.viewController)
    }

    func test_masterViewController_whenServerChanged_shouldBeChanged() {
        // swiftlint:disable:next force_cast
        let masterNavigationController = splitViewController.viewControllers[0] as! UINavigationController
        session.setServer(.transmissionMock())
        let firstViewController = masterNavigationController.viewControllers[0]
        session.setServer(.transmissionMock())
        let secondViewController = masterNavigationController.viewControllers[0]
        XCTAssertNotEqual(firstViewController, secondViewController)
    }

    func test_addTorrentFile_shouldPresentAlertController() {
        session.setServer(.transmissionMock())
        coordinator.addTorrentFile(at: URL(fileURLWithPath: "/file.torrent", isDirectory: false))
        // swiftlint:disable:next force_cast
        let alertController = splitViewController.presentedViewController as! UIAlertController
        XCTAssertEqual(alertController.title, "Add Torrent")
        XCTAssertEqual(alertController.message, "Add file.torrent to Server?")
        XCTAssertEqual(alertController.actions.map { $0.title }, ["Add", "Cancel"])
    }

    // MARK: handle - TorrentListCoordinatorEvent

    func test_listCoordinator_showSettingsEvent_shouldShowSettings() throws {
        coordinator.handle(.showSettings)
        // swiftlint:disable:next force_cast
        let navigationController = splitViewController.presentedViewController as! UINavigationController
        let viewController = navigationController.viewControllers[0]
        guard type(of: viewController) === SettingsViewController<SettingsViewModel>.self else {
            XCTFail("Unexpected view controller: \(String(describing: viewController))")
            return
        }
    }

    func test_listCoordinator_showDetailEvent_shouldShowDetail() throws {
        coordinator.handle(.showDetail(viewModel: AnyEmitterViewModel(MockTorrentDetailViewModel())))
        // swiftlint:disable:next force_cast
        let navigationController = splitViewController.detailViewController as! UINavigationController
        let viewController = navigationController.viewControllers[0]
        guard type(of: viewController) === TorrentDetailViewController<AnyTorrentDetailViewModel>.self else {
            XCTFail("Unexpected view controller: \(String(describing: viewController))")
            return
        }
    }

    func test_listCoordinator_commitDetail_shouldCommitDetail() throws {
        let viewModel = AnyTorrentDetailViewModel(MockTorrentDetailViewModel())
        let detailCoordinator = TorrentDetailCoordinator(viewModel: viewModel)
        coordinator.handle(TorrentListCoordinatorEvent.commitDetail(coordinator: detailCoordinator))
        // swiftlint:disable:next force_cast
        let navigationController = splitViewController.detailViewController as! UINavigationController
        let viewController = navigationController.viewControllers[0]
        guard type(of: viewController) === TorrentDetailViewController<AnyTorrentDetailViewModel>.self else {
            XCTFail("Unexpected view controller: \(String(describing: viewController))")
            return
        }
    }

    // MARK: handle - SettingsCoordinatorEvent

    func test_settingsCoordinator_completeEvent_shouldDismiss() {
        let viewController = MockPresentableViewController()
        coordinator.handle(SettingsCoordinatorEvent.complete, from: MockCoordinator(viewController: viewController))
        XCTAssertEqual(viewController.dismissCallCount, 1)
        XCTAssertEqual(viewController.dismissParamAnimated, [true])
    }

    // MARK: handle - TorrentDetailCoordinatorEvent

    func test_detailCoordinator_completeEvent_shouldDismiss() {
        let previousDetailViewController = splitViewController.detailViewController
        XCTAssertNotNil(previousDetailViewController)
        coordinator.handle(
            TorrentDetailCoordinatorEvent.complete,
            from: MockCoordinator(viewController: MockPresentableViewController())
        )
        XCTAssertNotEqual(splitViewController.detailViewController, previousDetailViewController)
        // unfortunately not much else we can test here :(
    }
}

// MARK: - Mocks

private final class MockSplitViewController: PresentableSplitViewController {
    private(set) var detailViewController: UIViewController?

    override var viewControllers: [UIViewController] {
        didSet {
            if viewControllers.count > 1 {
                detailViewController = viewControllers[1]
            }
        }
    }

    // swiftlint:disable:next identifier_name
    override func showDetailViewController(_ vc: UIViewController, sender: Any?) {
        detailViewController = vc
    }
}

private final class MockTorrentDetailViewModel: ViewModel, EventEmitter {
    let state = TorrentDetailViewState(
        sections: Just([]).eraseToAnyPublisher(),
        isLoading: Just(false).eraseToAnyPublisher()
    )
    let events: AnyPublisher<TorrentDetailEvent, Never> = Empty().eraseToAnyPublisher()
    func handle(_ event: TorrentDetailViewEvent) {}
}
