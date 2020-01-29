//
//  TorrentListCoordinator.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-16.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import Coordinator
import Preferences
import UIKit

enum TorrentListCoordinatorEvent {
    case detail(viewModel: AnyTorrentDetailViewModel)
    case settings
}

final class TorrentListCoordinator: Coordinator, AlertPresenter {
    private let viewModel: AnyTorrentListViewModel
    private let session: Session
    private let preferences: Preferences
    private let viewController: TorrentListViewController<AnyTorrentListViewModel>
    private let eventSubject = PassthroughSubject<TorrentListCoordinatorEvent, Never>()
    var observers = [AnyCancellable]()
    var childCoordinators = [AnyHashable: AnyCoordinator]()

    var presentable: Presentable {
        return viewController
    }

    var events: AnyPublisher<TorrentListCoordinatorEvent, Never> {
        return eventSubject.eraseToAnyPublisher()
    }

    var received: AnyPublisher<TorrentListEvent, Never> {
        return viewModel.events.eraseToAnyPublisher()
    }

    init(server: Server?, session: Session, preferences: Preferences) {
        viewModel = server?.listViewModel(preferences: preferences) ?? AnyProducerViewModel(EmptyTorrentListViewModel())
        self.session = session
        self.preferences = preferences
        viewController = TorrentListViewController(viewModel: viewModel)
    }

    func handle(_ event: TorrentListEvent) {
        switch event {
        case let .add(source, linkSubject):
            showAdd(from: source, linkSubject: linkSubject)
        case let .detail(viewModel: viewModel):
            eventSubject.send(.detail(viewModel: viewModel))
        case .settings:
            eventSubject.send(.settings)
        case let .alert(alert, source):
            showAlert(alert, from: source)
        }
    }

    func showAdd(from source: PopoverSource, linkSubject: PassthroughSubject<String, Never>) {
        var alert = Alert(title: "Add Torrent", message: "How would you like to add the torrent?", style: .actionSheet)
        alert.addAction(AlertAction(title: "Add Link", style: .default) {
            self.showAddLink(subject: linkSubject)
        })
        alert.addAction(AlertAction(title: "Add File", style: .default) {
            // TODO:
        })
        alert.addAction(AlertAction(title: "Cancel", style: .cancel))
        showAlert(alert, from: source)
    }

    private func showAddLink(subject: PassthroughSubject<String, Never>) {
        let alertController = UIAlertController(
            title: "Enter a URL",
            message: "This can be either a link to a torrent or a magnet link.",
            preferredStyle: .alert
        )
        alertController.addTextField { textField in
            textField.textContentType = .URL
            textField.placeholder = "magnet:?xt=urn:btih:c12fe1c06bba254a9dc9f519b335aa7c1367a88a"
        }
        alertController.addAction(UIAlertAction(title: "Add", style: .default) { _ in
            subject.send(alertController.textFields?.first?.text ?? "")
            subject.send(completion: .finished)
        })
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        viewController.present(alertController, animated: true, completion: nil)
    }
}
