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
    private lazy var session = DefaultSession(preferences: preferences)
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

    private func createServer(name: String = "Server") throws -> Server {
        return Server(
            name: name,
            type: .transmission,
            data: try JSONEncoder().encode(TransmissionServerSettings(
                url: URL(string: "http://localhost")!,
                username: nil
            )),
            keychainData: try JSONEncoder().encode(TransmissionKeychainData())
        )
    }

    func test_masterViewController_whenServerChanged_shouldBeChanged() throws {
        // swiftlint:disable force_cast
        let masterNavigationController = splitViewController.viewControllers[0] as! UINavigationController
        session.setServer(try createServer())
        let firstViewController = masterNavigationController.viewControllers[0]
        session.setServer(try createServer())
        let secondViewController = masterNavigationController.viewControllers[0]
        XCTAssertNotEqual(firstViewController, secondViewController)
    }

    func test_addTorrentFile_shouldPresentAlertController() throws {
        session.setServer(try createServer())
        coordinator.addTorrentFile(at: URL(fileURLWithPath: "/file.torrent", isDirectory: false))
        let alertController = splitViewController.presentedViewController as! UIAlertController
        XCTAssertEqual(alertController.title, "Add Torrent")
        XCTAssertEqual(alertController.message, "Add file.torrent to Server?")
        XCTAssertEqual(alertController.actions.map { $0.title }, ["Add", "Cancel"])
    }

    // MARK: handle - TorrentListCoordinatorEvent

    func test_listCoordinator_settingsEvent_shouldShowSettings() throws {
        // swiftlint:disable force_cast
        coordinator.handle(.settings)
        let navigationController = splitViewController.presentedViewController as! UINavigationController
        let viewController = navigationController.viewControllers[0]
        guard type(of: viewController) === SettingsViewController<SettingsViewModel>.self else {
            XCTFail("Unexpected view controller: \(String(describing: viewController))")
            return
        }
    }

    func test_listCoordinator_detailEvent_shouldShowDetail() throws {
        // swiftlint:disable force_cast
        coordinator.handle(.detail(viewModel: AnyEmitterViewModel(MockTorrentDetailViewModel())))
        let navigationController = splitViewController.detailViewController as! UINavigationController
        let viewController = navigationController.viewControllers[0]
        guard type(of: viewController) === TorrentDetailViewController<AnyTorrentDetailViewModel>.self else {
            XCTFail("Unexpected view controller: \(String(describing: viewController))")
            return
        }
    }

    // MARK: handle - SettingsCoordinatorEvent

    func test_settingsCoordinator_completeEvent_shouldDismiss() {
        let settingsCoordinator = MockCoordinator()
        coordinator.handle(SettingsCoordinatorEvent.complete, from: settingsCoordinator)
        XCTAssertEqual(settingsCoordinator.viewController.dismissCallCount, 1)
        XCTAssertEqual(settingsCoordinator.viewController.dismissParamAnimated, [true])
    }

    // MARK: handle - TorrentDetailCoordinatorEvent

    func test_detailCoordinator_completeEvent_shouldDismiss() {
        let previousDetailViewController = splitViewController.detailViewController
        XCTAssertNotNil(previousDetailViewController)
        coordinator.handle(TorrentDetailCoordinatorEvent.complete, from: MockCoordinator())
        XCTAssertNotEqual(splitViewController.detailViewController, previousDetailViewController)
        // unfortunately not much else we can test here :(
    }
}

// MARK: - Mocks

private final class MockCoordinator: Coordinator {
    let viewController = MockViewController()
    let events: AnyPublisher<Never, Never> = Empty().eraseToAnyPublisher()
    let received: AnyPublisher<Never, Never> = Empty().eraseToAnyPublisher()
    var observers = [AnyCancellable]()
    var childCoordinators = [AnyHashable: AnyCoordinator]()
    var presentable: Presentable { viewController }
}

private final class MockViewController: PresentableViewController {
    private(set) var presentCallCount = 0
    private(set) var presentParamViewController = [UIViewController]()
    private(set) var presentParamAnimated = [Bool]()
    override func present(
        _ viewControllerToPresent: UIViewController,
        animated flag: Bool,
        completion: (() -> Void)? = nil
    ) {
        super.present(viewController, animated: flag, completion: completion)
        presentCallCount += 1
        presentParamViewController.append(viewControllerToPresent)
        presentParamAnimated.append(flag)
    }

    private(set) var dismissCallCount = 0
    private(set) var dismissParamAnimated = [Bool]()
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        super.dismiss(animated: flag, completion: completion)
        dismissCallCount += 1
        dismissParamAnimated.append(flag)
    }
}

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
