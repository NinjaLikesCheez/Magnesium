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
import UIKit

protocol ServerSettingsCoordinator: Coordinator, AlertPresenter {
    var didComplete: AnyPublisher<Void, Never> { get }
    func complete()
}

final class DefaultServerSettingsCoordinator: ServerSettingsCoordinator {
    private let server: Server
    private let preferences: Preferences
    private let didCompleteSubject = PassthroughSubject<Void, Never>()
    var observers = [AnyCancellable]()
    var childCoordinators = [Coordinator]()

    private lazy var viewController: ServerSettingsViewController = {
        let viewModel: ServerSettingsViewModel
        switch server.type {
        case .deluge:
            viewModel = DelugeSettingsViewModel(coordinator: self, preferences: preferences, server: server)
        case .transmission:
            viewModel = TransmissionSettingsViewModel(coordinator: self, preferences: preferences, server: server)
        }

        return ServerSettingsViewController(viewModel: viewModel)
    }()

    var presentable: Presentable {
        return viewController
    }

    var didComplete: AnyPublisher<Void, Never> {
        return didCompleteSubject.eraseToAnyPublisher()
    }

    init(server: Server, preferences: Preferences) {
        self.server = server
        self.preferences = preferences
    }

    func complete() {
        didCompleteSubject.send(())
        didCompleteSubject.send(completion: .finished)
    }
}
