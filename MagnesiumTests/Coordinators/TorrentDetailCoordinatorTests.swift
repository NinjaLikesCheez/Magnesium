//
//  TorrentDetailCoordinatorTests.swift
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

class TorrentDetailCoordinatorTests: XCTestCase {
    private let window = UIWindow()
    private let viewModel = MockViewModel()
    private var coordinator: TorrentDetailCoordinator<AnyTorrentDetailViewModel>!
    private var observers = [AnyCancellable]()

    override func setUp() {
        super.setUp()
        coordinator = TorrentDetailCoordinator(viewModel: AnyEmitterViewModel(viewModel))
        coordinator.received.sink { [weak coordinator] in coordinator?.handle($0) }.store(in: &observers)

        // the view controller needs to be in a key window to perform a presentation
        window.rootViewController = coordinator.presentable.viewController
        window.makeKeyAndVisible()
    }

    func test_presentable_shouldBeTorrentDetailViewController() {
        let viewController = coordinator.presentable.viewController
        guard type(of: viewController) === TorrentDetailViewController<AnyTorrentDetailViewModel>.self else {
            XCTFail("Unexpected view controller: \(String(describing: self))")
            return
        }
    }

    // MARK: handle - TorrentDetailEvent

    func test_viewModel_completeEvent_shouldEmitCompleteEvent() {
        var event: TorrentDetailCoordinatorEvent?
        coordinator.events.first().sink { event = $0 }.store(in: &observers)
        viewModel.eventSubject.send(.complete)
        guard case .complete = event else {
            XCTFail("Unexpected event: \(String(describing: event))")
            return
        }
    }

    func test_viewModel_alertEvent_shouldPresentAlertController() {
        viewModel.eventSubject.send(.alert(Alert(title: "", message: nil, style: .alert), source: nil))
        let viewController = coordinator.presentable.viewController
        guard type(of: viewController.presentedViewController!) === UIAlertController.self else {
            XCTFail("Unexpected view controller: \(String(describing: viewController.presentedViewController))")
            return
        }
    }

    func test_viewModel_activitiesEvent_shouldPresentActivityViewController() {
        viewModel.eventSubject.send(.activities(
            [],
            torrent: DelugeTorrent.mock(),
            source: .view(UIView(), rect: .zero)
        ))
        let viewController = coordinator.presentable.viewController
        guard type(of: viewController.presentedViewController!) === UIActivityViewController.self else {
            XCTFail("Unexpected view controller: \(String(describing: viewController.presentedViewController))")
            return
        }
    }
}

// MARK: - Mocks

private final class MockViewModel: ViewModel, EventEmitter {
    let state = TorrentDetailViewState(
        sections: Just([]).eraseToAnyPublisher(),
        isLoading: Just(false).eraseToAnyPublisher()
    )
    let eventSubject = PassthroughSubject<TorrentDetailEvent, Never>()
    var events: AnyPublisher<TorrentDetailEvent, Never> { eventSubject.eraseToAnyPublisher() }
    func handle(_ event: TorrentDetailViewEvent) {}
}
