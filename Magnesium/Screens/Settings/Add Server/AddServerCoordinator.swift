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
    private let didCompleteSubject = PassthroughSubject<Void, Never>()
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
        viewModel.events.sink { [weak self] in self?.handle(event: $0) }.store(in: &observers)
    }

    private func handle(event: AddServerEvent) {
        switch event {
        case let .selected(type: type):
            showServerSettings(for: type)
        }
    }

    private func handle(event: ServerSettingsEvent) {
        switch event {
        case .complete:
            eventSubject.send(.complete)
        case let .alert(alert, source: source):
            showAlert(alert, from: source)
        }
    }

    private func showServerSettings(for type: ServerType) {
        let viewModel: ServerSettingsViewModel
        switch type {
        case .deluge:
            viewModel = DelugeSettingsViewModel(preferences: preferences)
        case .transmission:
            viewModel = TransmissionSettingsViewModel(preferences: preferences)
        }
        viewModel.events.sink { [weak self] in self?.handle(event: $0) }.store(in: &observers)
        let viewController = ServerSettingsViewController(viewModel: viewModel)
        self.viewController.navigationController?.pushViewController(viewController, animated: true)
    }
}
