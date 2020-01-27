//
//  TorrentDetailCoordinator.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-16.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import Coordinator

enum TorrentDetailCoordinatorEvent {
    case complete
}

protocol TorrentDetailCoordinator: Coordinator, AlertPresenter where Event == TorrentDetailCoordinatorEvent {}

final class DefaultTorrentDetailCoordinator: TorrentDetailCoordinator {
    private let navigationController: PresentableNavigationController
    private let eventSubject = PassthroughSubject<TorrentDetailCoordinatorEvent, Never>()
    let received: AnyPublisher<TorrentDetailEvent, Never>
    var observers = [AnyCancellable]()
    var childCoordinators = [AnyHashable: AnyCoordinator]()

    var presentable: Presentable {
        return navigationController
    }

    var events: AnyPublisher<TorrentDetailCoordinatorEvent, Never> {
        return eventSubject.eraseToAnyPublisher()
    }

    init(viewModel: TorrentDetailViewModel) {
        let viewController = TorrentDetailViewController(viewModel: viewModel)
        navigationController = PresentableNavigationController(rootViewController: viewController)
        received = viewModel.events.eraseToAnyPublisher()
    }

    func handle(event: TorrentDetailEvent) {
        switch event {
        case .complete:
            eventSubject.send(.complete)
        case let .alert(alert, source: source):
            showAlert(alert, from: source)
        }
    }
}
