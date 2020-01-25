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

protocol AddServerCoordinator: ServerSettingsCoordinator {
    func showServerSettings(for type: ServerType)
}

final class DefaultAddServerCoordinator: AddServerCoordinator {
    private let preferences: Preferences
    private let didCompleteSubject = PassthroughSubject<Void, Never>()
    var observers = [AnyCancellable]()
    var childCoordinators = [Coordinator]()

    private lazy var viewController: AddServerViewController = {
        let viewModel = DefaultAddServerViewModel(coordinator: self)
        return AddServerViewController(viewModel: viewModel)
    }()

    var presentable: Presentable {
        return viewController
    }

    var didComplete: AnyPublisher<Void, Never> {
        return didCompleteSubject.eraseToAnyPublisher()
    }

    init(preferences: Preferences) {
        self.preferences = preferences
    }

    func complete() {
        didCompleteSubject.send(())
        didCompleteSubject.send(completion: .finished)
    }

    func showServerSettings(for type: ServerType) {
        let viewModel: ServerSettingsViewModel
        switch type {
        case .deluge:
            viewModel = DelugeSettingsViewModel(coordinator: self, preferences: preferences)
        case .transmission:
            viewModel = TransmissionSettingsViewModel(coordinator: self, preferences: preferences)
        }

        let viewController = ServerSettingsViewController(viewModel: viewModel)
        self.viewController.navigationController?.pushViewController(viewController, animated: true)
    }
}
