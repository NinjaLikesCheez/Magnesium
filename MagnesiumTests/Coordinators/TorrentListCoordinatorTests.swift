//
//  TorrentListCoordinatorTests.swift
//  MagnesiumTests
//
//  Created by James Hurst on 2020-02-04.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import LinkPresentation
@testable import Magnesium
import ViewModel
import XCTest

class TorrentListCoordinatorTests: XCTestCase {
    private var window: UIWindow!
    private var viewModel: MockViewModel!
    private var preferences: MockPreferences!
    private var session: Session!
    private var coordinator: TorrentListCoordinator!
    private var observers = [AnyCancellable]()

    override func setUp() {
        super.setUp()
        window = UIWindow()
        viewModel = MockViewModel()
        preferences = MockPreferences()
        session = Session(preferences: preferences)
        coordinator = TorrentListCoordinator(
            viewModel: AnyTorrentListViewModel(viewModel),
            session: session,
            preferences: preferences
        )
        coordinator.received.sink { [weak coordinator] in coordinator?.handle($0) }.store(in: &observers)
        // the view controller needs to be in a key window to perform a presentation
        window.rootViewController = coordinator.presentable.viewController
        window.makeKeyAndVisible()
    }

    // MARK: - Presentable

    func test_presentable_shouldBeTorrentListViewController() {
        let viewController = coordinator.presentable.viewController
        guard type(of: viewController) === TorrentListViewController<AnyTorrentListViewModel>.self else {
            XCTFail("Unexpected view controller: \(String(describing: viewController))")
            return
        }
    }

    // MARK: - Add Torrent

    func test_showAddLink_shouldPresentAlertController() {
        coordinator.showAddLink(subject: .init())
        let viewController = coordinator.presentable.viewController
        // swiftlint:disable:next force_cast
        let alertController = viewController.presentedViewController as! UIAlertController
        XCTAssertEqual(alertController.title, "Enter a URL")
        XCTAssertEqual(alertController.message, "This can be either a link to a torrent or a magnet link.")
        XCTAssertEqual(alertController.actions.map { $0.title }, ["Add", "Cancel"])
        XCTAssertEqual(alertController.textFields?.count ?? 0, 1)
        XCTAssertEqual(alertController.preferredStyle, .alert)
    }

    func test_showAddFile_shouldPresentDocumentPickerViewController() {
        coordinator.showAddFile()
        let presentedViewController = coordinator.presentable.viewController.presentedViewController
        guard type(of: presentedViewController!) === UIDocumentPickerViewController.self else {
            XCTFail("Unexpected view controller: \(String(describing: presentedViewController))")
            return
        }
    }

    // MARK: - Handle TorrentListEvent

    func test_alert_shouldPresentAlertController() {
        viewModel.eventSubject.send(.alert(Alert(title: "", message: nil, style: .alert), source: nil))
        let presentedViewController = coordinator.presentable.viewController.presentedViewController
        guard type(of: presentedViewController!) === UIAlertController.self else {
            XCTFail("Unexpected view controller: \(String(describing: presentedViewController))")
            return
        }
    }

    func test_activities_shouldPresentActivityViewController() {
        viewModel.eventSubject.send(.activities(
            [],
            torrents: [DelugeTorrent.mock()],
            source: .view(UIView(), rect: .zero)
        ))
        let presentedViewController = coordinator.presentable.viewController.presentedViewController
        guard type(of: presentedViewController!) === UIActivityViewController.self else {
            XCTFail("Unexpected view controller: \(String(describing: presentedViewController))")
            return
        }
    }

    func test_add_shouldPresentAlertController() {
        viewModel.eventSubject.send(.add(source: .view(UIView(), rect: .zero), linkSubject: .init()))
        let viewController = coordinator.presentable.viewController
        // swiftlint:disable:next force_cast
        let alertController = viewController.presentedViewController as! UIAlertController
        XCTAssertEqual(alertController.title, "Add Torrent")
        XCTAssertEqual(alertController.message, "How would you like to add the torrent?")
        XCTAssertEqual(alertController.actions.map { $0.title }, ["Add Link", "Add File", "Cancel"])
        XCTAssertEqual(alertController.preferredStyle, .actionSheet)
    }

    func test_filter_shouldPresentFilterViewController() {
        viewModel.eventSubject.send(.filter(
            source: .view(UIView(), rect: .zero),
            labels: CurrentValueSubject([])
        ))
        let viewController = coordinator.presentable.viewController
        // swiftlint:disable:next force_cast
        let navigationController = viewController.presentedViewController as! UINavigationController
        XCTAssertEqual(navigationController.modalPresentationStyle, .popover)
        let rootViewController = navigationController.viewControllers[0]
        guard type(of: rootViewController) === FilterViewController<FilterViewModel>.self else {
            XCTFail("Unexpected view controller: \(String(describing: viewController))")
            return
        }
    }

    func test_detail_shouldEmitShowDetailEvent() {
        var event: TorrentListCoordinatorEvent?
        coordinator.events.first().sink { event = $0 }.store(in: &observers)
        let detailViewModel = AnyEmitterViewModel(MockDetailViewModel())
        viewModel.eventSubject.send(.detail(viewModel: detailViewModel))
        guard case let .showDetail(viewModel) = event else {
            XCTFail("Unexpected event: \(String(describing: event))")
            return
        }
        XCTAssertTrue(detailViewModel === viewModel)
    }

    func test_settings_shouldEmitShowSettingsEvent() {
        var event: TorrentListCoordinatorEvent?
        coordinator.events.first().sink { event = $0 }.store(in: &observers)
        viewModel.eventSubject.send(.settings)
        guard case .showSettings = event else {
            XCTFail("Unexpected event: \(String(describing: event))")
            return
        }
    }

    func test_moveDownloadFolder_shouldPresentAlertController() {
        viewModel.eventSubject.send(.moveDownloadFolder(currentPath: "/path", subject: PassthroughSubject()))
        let viewController = coordinator.presentable.viewController
        // swiftlint:disable:next force_cast
        let alertController = viewController.presentedViewController as! UIAlertController
        XCTAssertEqual(alertController.title, "Move Download Folder")
        XCTAssertEqual(alertController.actions.map { $0.title }, ["Save", "Cancel"])
        XCTAssertEqual(alertController.textFields?.count ?? 0, 1)
        let textField = alertController.textFields![0]
        XCTAssertEqual(textField.textContentType, .URL)
        XCTAssertEqual(textField.placeholder, "/downloads")
        XCTAssertEqual(textField.text, "/path")
    }

    // MARK: - Handle FilterCoordinatorEvent

    func test_filterCoordinatorEvent_complete_shouldDismiss() {
        let viewController = MockPresentableViewController()
        coordinator.handle(FilterCoordinatorEvent.complete, from: MockCoordinator(viewController: viewController))
        XCTAssertEqual(viewController.dismissCallCount, 1)
        XCTAssertEqual(viewController.dismissParamAnimated, [true])
    }

    // MARK: - TorrentListPreviewProvider

    func test_previewForItem_shouldAddDetailChildCoordinator() {
        let viewController = coordinator.previewForItem(at: 0)
        XCTAssertNotNil(viewController)
        XCTAssertEqual(coordinator.childCoordinators.count, 1)
        let childCoordinator = coordinator.childCoordinators.values.first!.base as AnyObject
        guard type(of: childCoordinator) === TorrentDetailCoordinator<AnyTorrentDetailViewModel>.self else {
            XCTFail("Unexpected coordinator: \(String(describing: coordinator))")
            return
        }
    }

    func test_contextMenuForItem_shouldReturnExpectedMenu() {
        let menu = coordinator.contextMenuForItem(at: 0)
        XCTAssertEqual(menu?.identifier.rawValue, "mock")
    }

    func test_commitPreviews_shouldEmitCommitDetailEvent_withSameCoordinator() {
        var event: TorrentListCoordinatorEvent?
        coordinator.events.first().sink { event = $0 }.store(in: &observers)
        XCTAssertNotNil(coordinator.previewForItem(at: 0))
        let childCoordinator = coordinator.childCoordinators.values.first?.base
            as! TorrentDetailCoordinator<AnyTorrentDetailViewModel> // swiftlint:disable:this force_cast
        coordinator.commitPreviewForItem(at: 0)
        guard case let .commitDetail(committedCoordinator) = event else {
            XCTFail("Unexpected event: \(String(describing: event))")
            return
        }
        XCTAssertTrue(childCoordinator === committedCoordinator)
    }

    func test_commitPreviewForItem_shouldRemoveChildCoordinator() {
        XCTAssertNotNil(coordinator.previewForItem(at: 0))
        XCTAssertEqual(coordinator.childCoordinators.count, 1)
        var childCoordinator = coordinator.childCoordinators.values.first!.base as AnyObject
        coordinator.commitPreviewForItem(at: 0)
        XCTAssertTrue(coordinator.childCoordinators.isEmpty)
        XCTAssertTrue(isKnownUniquelyReferenced(&childCoordinator))
    }

    func test_cleanupPreviewForItem_shouldRemovePreviewCoordinatorFromCache() {
        XCTAssertNotNil(coordinator.previewForItem(at: 0))
        XCTAssertEqual(coordinator.childCoordinators.count, 1)
        var childCoordinator = coordinator.childCoordinators.values.first!.base as AnyObject
        // remove the child coordinator so the only reference should be the preview cache
        coordinator.childCoordinators.removeAll()
        XCTAssertFalse(isKnownUniquelyReferenced(&childCoordinator))
        coordinator.didDismissPreviewForItem(at: 0)
        let expectation = self.expectation(description: "")
        DispatchQueue.main.async {
            XCTAssertTrue(isKnownUniquelyReferenced(&childCoordinator))
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func test_leadingSwipeActionsConfigurationForItem_shouldReturnExpectedActions() {
        let configuration = coordinator.leadingSwipeActionsConfigurationForItem(
            at: 0,
            source: .view(UIView(), rect: .zero)
        )!
        XCTAssertEqual(configuration.actions.count, 1)
        XCTAssertEqual(configuration.actions[0].title, "leadingMock")
    }

    func test_trailingSwipeActionsConfigurationForItem_shouldReturnExpectedActions() {
        let configuration = coordinator.trailingSwipeActionsConfigurationForItem(
            at: 0,
            source: .view(UIView(), rect: .zero)
        )!
        XCTAssertEqual(configuration.actions.count, 1)
        XCTAssertEqual(configuration.actions[0].title, "trailingMock")
    }
}

// MARK: - Mocks

private final class MockViewModel: ViewModel, EventEmitter, TorrentListProvider {
    let state = TorrentListViewState(
        title: Just("").eraseToAnyPublisher(),
        items: Just([]).eraseToAnyPublisher(),
        isLoading: Just(false).eraseToAnyPublisher(),
        hasActiveFilters: Just(false).eraseToAnyPublisher(),
        editActionsEnabled: Just(false).eraseToAnyPublisher()
    )
    let eventSubject = PassthroughSubject<TorrentListEvent, Never>()
    var events: AnyPublisher<TorrentListEvent, Never> { eventSubject.eraseToAnyPublisher() }
    func handle(_ event: TorrentListViewEvent) {}

    private(set) var previewViewModels = [AnyTorrentDetailViewModel]()
    func detailViewModelForItem(at index: Int) -> AnyTorrentDetailViewModel? {
        let torrent = CurrentValueSubject<DelugeTorrent, Never>(DelugeTorrent.mock())
        let labels = CurrentValueSubject<[DelugeLabel], Never>([.mock()])
        let preferences = MockPreferences()
        let client = MockDelugeClient()
        let refresher = MockDelugeRefresher()
        let viewModel = AnyTorrentDetailViewModel(StandardTorrentDetailViewModel(
            implementation: DelugeTorrentDetailViewModelImplementation(client: client, refresher: refresher),
            torrent: torrent,
            labels: labels,
            preferences: preferences
        ))
        previewViewModels.append(viewModel)
        return viewModel
    }

    func contextMenuForItem(at index: Int) -> UIMenu? {
        return UIMenu(title: "Menu", identifier: UIMenu.Identifier(rawValue: "mock"))
    }

    func leadingSwipeActionsConfigurationForItem(at index: Int, source: PopoverSource) -> UISwipeActionsConfiguration? {
        return UISwipeActionsConfiguration(actions: [
            UIContextualAction(style: .normal, title: "leadingMock", handler: { _, _, _ in }),
        ])
    }

    func trailingSwipeActionsConfigurationForItem(
        at index: Int,
        source: PopoverSource
    ) -> UISwipeActionsConfiguration? {
        return UISwipeActionsConfiguration(actions: [
            UIContextualAction(style: .normal, title: "trailingMock", handler: { _, _, _ in }),
        ])
    }
}

private final class MockDetailViewModel: ViewModel, EventEmitter {
    let state = TorrentDetailViewState(
        sections: Just([]).eraseToAnyPublisher(),
        isRefreshing: Just(false).eraseToAnyPublisher()
    )
    let events: AnyPublisher<TorrentDetailEvent, Never> = Empty().eraseToAnyPublisher()
    func handle(_ event: TorrentDetailViewEvent) {}
}
