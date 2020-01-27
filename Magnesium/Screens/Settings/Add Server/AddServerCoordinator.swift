//
//  AddServerCoordinator.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-16.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import Coordinator
import Preferences
import UIKit

enum AddServerCoordinatorEvent {
    case complete
}

protocol AddServerCoordinator: Coordinator where Event == AddServerCoordinatorEvent {}

final class DefaultAddServerCoordinator: AddServerCoordinator, AlertPresenter {
    private let preferences: Preferences
    private let eventSubject = PassthroughSubject<AddServerCoordinatorEvent, Never>()
    private let viewController: AddServerViewController
    let received: AnyPublisher<AddServerEvent, Never>
    var observers = [AnyCancellable]()
    var childCoordinators = [AnyHashable: AnyCoordinator]()

    var presentable: Presentable {
        return viewController
    }

    var events: AnyPublisher<AddServerCoordinatorEvent, Never> {
        return eventSubject.eraseToAnyPublisher()
    }

    init(preferences: Preferences) {
        self.preferences = preferences
        let viewModel = DefaultAddServerViewModel()
        viewController = AddServerViewController(viewModel: viewModel)
        received = viewModel.events.eraseToAnyPublisher()
    }

    func handle(event: AddServerEvent) {
        switch event {
        case let .selected(type: type):
            showServerSettings(for: type)
        }
    }

    private func showServerSettings(for type: ServerType) {
        let coordinator = DefaultServerSettingsCoordinator(type: type, preferences: preferences)
        addChildCoordinator(coordinator) { [weak self] _, event in
            switch event {
            case .complete:
                self?.eventSubject.send(.complete)
            }
        }
        viewController.navigationController?.pushViewController(coordinator.presentable.viewController, animated: true)
    }
}
