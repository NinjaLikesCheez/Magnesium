//
//  TorrentListCoordinatorTests.swift
//  MagnesiumTests
//
//  Created by James Hurst on 2020-02-04.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
@testable import Magnesium
import ViewModel
import XCTest

class TorrentListCoordinatorTests: XCTestCase {
    private let window = UIWindow()
    private let viewModel = MockViewModel()
    private let preferences = MockPreferences()
    private lazy var session = DefaultSession(preferences: preferences)
    private var coordinator: TorrentListCoordinator!
    private var observers = [AnyCancellable]()

    override func setUp() {
        super.setUp()
        coordinator = TorrentListCoordinator(
            viewModel: AnyEmitterViewModel(viewModel),
            session: session,
            preferences: preferences
        )
        coordinator.received.sink { [weak coordinator] in coordinator?.handle($0) }.store(in: &observers)

        // the view controller needs to be in a key window to perform a presentation
        window.rootViewController = coordinator.presentable.viewController
        window.makeKeyAndVisible()
    }

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

    // MARK: handle - TorrentListEvent

    func test_viewModel_alertEvent_shouldPresentAlertController() {
        viewModel.eventSubject.send(.alert(Alert(title: "Alert", message: nil, style: .alert), source: nil))
        let presentedViewController = coordinator.presentable.viewController.presentedViewController
        guard type(of: presentedViewController!) === UIAlertController.self else {
            XCTFail("Unexpected view controller: \(String(describing: presentedViewController))")
            return
        }
    }

    func test_viewModel_addEvent_shouldPresentAlertController() {
        viewModel.eventSubject.send(.add(source: .view(UIView(), rect: .zero), linkSubject: .init()))
        let viewController = coordinator.presentable.viewController
        // swiftlint:disable:next force_cast
        let alertController = viewController.presentedViewController as! UIAlertController
        XCTAssertEqual(alertController.title, "Add Torrent")
        XCTAssertEqual(alertController.message, "How would you like to add the torrent?")
        XCTAssertEqual(alertController.actions.map { $0.title }, ["Add Link", "Add File", "Cancel"])
        XCTAssertEqual(alertController.preferredStyle, .actionSheet)
    }

    func test_viewModel_filterEvent_shouldPresentFilterViewController() {
        viewModel.eventSubject.send(.filter(source: .view(UIView(), rect: .zero)))
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

    func test_viewModel_detailEvent_shouldEmitDetailEvent() {
        var event: TorrentListCoordinatorEvent?
        coordinator.events.sink { event = $0 }.store(in: &observers)
        let detailViewModel = AnyEmitterViewModel(MockDetailViewModel())
        viewModel.eventSubject.send(.detail(viewModel: detailViewModel))
        guard case let .detail(viewModel) = event else {
            XCTFail("Unexpected event: \(String(describing: event))")
            return
        }
        XCTAssertTrue(detailViewModel === viewModel)
    }

    func test_viewModel_settingsEvent_shouldEmitDetailEvent() {
        var event: TorrentListCoordinatorEvent?
        coordinator.events.sink { event = $0 }.store(in: &observers)
        viewModel.eventSubject.send(.settings)
        guard case .settings = event else {
            XCTFail("Unexpected event: \(String(describing: event))")
            return
        }
    }

    // MARK: handle - FilterCoordinatorEvent

    func test_filterCoordinator_completeEvent_shouldDismiss() {
        let mockCoordinator = MockCoordinator()
        coordinator.handle(FilterCoordinatorEvent.complete, from: mockCoordinator)
        XCTAssertEqual(mockCoordinator.viewController.dismissCallCount, 1)
        XCTAssertEqual(mockCoordinator.viewController.dismissParamAnimated, [true])
    }
}

// MARK: - Mocks

private final class MockViewModel: ViewModel, EventEmitter {
    let state = TorrentListViewState(
        items: Just([]).eraseToAnyPublisher(),
        isLoading: Just(false).eraseToAnyPublisher()
    )
    let eventSubject = PassthroughSubject<TorrentListEvent, Never>()
    var events: AnyPublisher<TorrentListEvent, Never> { eventSubject.eraseToAnyPublisher() }
    func handle(_ event: TorrentListViewEvent) {}
}

private final class MockDetailViewModel: ViewModel, EventEmitter {
    let state = TorrentDetailViewState(
        sections: Just([]).eraseToAnyPublisher(),
        isLoading: Just(false).eraseToAnyPublisher()
    )
    let events: AnyPublisher<TorrentDetailEvent, Never> = Empty().eraseToAnyPublisher()
    func handle(_ event: TorrentDetailViewEvent) {}
}
