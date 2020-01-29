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

final class ServerSettingsCoordinator: Coordinator, AlertPresenter {
    private let viewController: ServerSettingsViewController
    private let eventSubject = PassthroughSubject<ServerSettingsCoordinatorEvent, Never>()
    let received: AnyPublisher<ServerSettingsEvent, Never>
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
        received = viewModel.events
    }

    init(type: ServerType, preferences: Preferences) {
        let viewModel: ServerSettingsViewModel
        switch type {
        case .deluge:
            viewModel = DelugeSettingsViewModel(preferences: preferences)
        case .transmission:
            viewModel = TransmissionSettingsViewModel(preferences: preferences)
        }

        received = viewModel.events
        viewController = ServerSettingsViewController(viewModel: viewModel)
    }

    func handle(_ event: ServerSettingsEvent) {
        switch event {
        case .complete:
            eventSubject.send(.complete)
        case let .alert(alert, source: source):
            showAlert(alert, from: source)
        }
    }
}
