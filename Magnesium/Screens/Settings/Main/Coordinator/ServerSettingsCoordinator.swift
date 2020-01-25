//
//  EditServerCoordinator.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-16.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import Coordinator
import Preferences

enum ServerSettingsCoordinatorEvent {
    case complete
}

protocol ServerSettingsCoordinator: Coordinator where Event == ServerSettingsCoordinatorEvent {}

final class DefaultServerSettingsCoordinator: ServerSettingsCoordinator, AlertPresenter {
    private let viewController: ServerSettingsViewController
    private let eventSubject = PassthroughSubject<ServerSettingsCoordinatorEvent, Never>()
    var observers = [AnyCancellable]()
    var childCoordinators = [AnyHashable: AnyCoordinator]()

    var presentable: Presentable {
        return viewController
    }

    var events: AnyPublisher<ServerSettingsCoordinatorEvent, Never> {
        return eventSubject.eraseToAnyPublisher()
    }

    init(server: Server, preferences: Preferences) {
        let viewModel: ServerSettingsViewModel
        switch server.type {
        case .deluge:
            viewModel = DelugeSettingsViewModel(preferences: preferences, server: server)
        case .transmission:
            viewModel = TransmissionSettingsViewModel(preferences: preferences, server: server)
        }

        viewController = ServerSettingsViewController(viewModel: viewModel)
        viewModel.events.sink { [weak self] in self?.handle(event: $0) }.store(in: &observers)
    }

    private func handle(event: ServerSettingsEvent) {
        switch event {
        case .complete:
            eventSubject.send(.complete)
        case let .alert(alert, source: source):
            showAlert(alert, from: source)
        }
    }
}
