//
//  TorrentDetailCoordinator.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-16.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import Coordinator
import UIKit

protocol TorrentDetailCoordinator: Coordinator, AlertPresenter {
    var didComplete: AnyPublisher<Void, Never> { get }
    func complete()
}

final class DefaultTorrentDetailCoordinator: TorrentDetailCoordinator {
    private let viewModel: TorrentDetailViewModel
    private let didCompleteSubject = PassthroughSubject<Void, Never>()
    var observers = [AnyCancellable]()
    var childCoordinators = [Coordinator]()

    private lazy var navigationController: PresentableNavigationController = {
        let viewController = TorrentDetailViewController(viewModel: viewModel)
        return PresentableNavigationController(rootViewController: viewController)
    }()

    var presentable: Presentable {
        return navigationController
    }

    var didComplete: AnyPublisher<Void, Never> {
        return didCompleteSubject.eraseToAnyPublisher()
    }

    init(viewModel: TorrentDetailViewModel) {
        self.viewModel = viewModel
    }

    func complete() {
        didCompleteSubject.send(())
        didCompleteSubject.send(completion: .finished)
    }
}
