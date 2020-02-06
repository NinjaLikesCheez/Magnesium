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

final class AddServerCoordinator: Coordinator, AlertPresenter {
    private let preferences: Preferences
    private let eventSubject = PassthroughSubject<AddServerCoordinatorEvent, Never>()
    private let viewController: AddServerViewController<AddServerViewModel>
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
        let viewModel = AddServerViewModel()
        viewController = AddServerViewController(viewModel: viewModel)
        received = viewModel.events
    }

    func handle(_ event: AddServerEvent) {
        switch event {
        case let .add(type: type):
            showServerSettings(for: type)
        }
    }

    private func showServerSettings(for type: ServerType) {
        let coordinator = ServerSettingsCoordinator(type: type, preferences: preferences)
        addChildCoordinator(coordinator) { [weak self] _, event in
            self?.handle(event)
        }
        viewController.navigationController?.pushViewController(coordinator.presentable.viewController, animated: true)
    }

    // internal for testing
    func handle(_ event: ServerSettingsCoordinatorEvent) {
        switch event {
        case .complete:
            eventSubject.send(.complete)
        }
    }
}
