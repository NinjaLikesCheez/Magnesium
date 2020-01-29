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

final class TorrentDetailCoordinator<VM: ViewModel & EventProducer>: Coordinator, AlertPresenter
    where
    VM.Event == TorrentDetailEvent,
    VM.ViewEvent == TorrentDetailViewEvent,
    VM.ViewState == TorrentDetailViewState {
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

    init(viewModel: VM) {
        let viewController = TorrentDetailViewController(viewModel: viewModel)
        navigationController = PresentableNavigationController(rootViewController: viewController)
        received = viewModel.events
    }

    func handle(_ event: TorrentDetailEvent) {
        switch event {
        case .complete:
            eventSubject.send(.complete)
        case let .alert(alert, source: source):
            showAlert(alert, from: source)
        }
    }
}
