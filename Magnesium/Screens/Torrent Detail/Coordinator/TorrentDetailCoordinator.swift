//
//  TorrentDetailCoordinator.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-16.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import Coordinator
import LinkPresentation
import UIKit
import ViewModel

enum TorrentDetailCoordinatorEvent {
    case complete
}

final class TorrentDetailCoordinator<VM: ViewModel & EventEmitter>: Coordinator, AlertPresenter
    where
    VM.Event == TorrentDetailEvent,
    VM.ViewEvent == TorrentDetailViewEvent,
    VM.ViewState == TorrentDetailViewState {
    private let viewController: TorrentDetailViewController<VM>
    private let eventSubject = PassthroughSubject<TorrentDetailCoordinatorEvent, Never>()
    let received: AnyPublisher<TorrentDetailEvent, Never>
    var observers = [AnyCancellable]()
    var childCoordinators = [AnyHashable: AnyCoordinator]()

    var presentable: Presentable {
        return viewController
    }

    var events: AnyPublisher<TorrentDetailCoordinatorEvent, Never> {
        return eventSubject.eraseToAnyPublisher()
    }

    init(viewModel: VM) {
        viewController = TorrentDetailViewController(viewModel: viewModel)
        received = viewModel.events
    }

    func handle(_ event: TorrentDetailEvent) {
        switch event {
        case .complete:
            eventSubject.send(.complete)
        case let .alert(alert, source):
            showAlert(alert, from: source)
        case let .activities(activities, torrent, source):
            showActivities(activities, torrent: torrent, source: source)
        case let .moveDownloadFolder(currentPath, subject):
            showMoveDownloadFolder(currentPath: currentPath, subject: subject)
        }
    }

    private func showActivities(_ activities: [Activity], torrent: StandardTorrent, source: PopoverSource) {
        let activityController = UIActivityViewController(
            activityItems: [ActivityMetadataItem(metadata: LPLinkMetadata(torrents: [torrent]))],
            applicationActivities: activities.map { $0.createUIActivity() }
        )
        activityController.configure(popoverSource: source)
        viewController.present(activityController, animated: true)
    }

    private func showMoveDownloadFolder(currentPath: String?, subject: PassthroughSubject<String, Never>) {
        let alertController = UIAlertController(
            title: L10n.moveDownloadFolder,
            message: nil,
            preferredStyle: .alert
        )
        alertController.addTextField { textField in
            textField.textContentType = .URL
            textField.placeholder = "/downloads"
            textField.text = currentPath
        }
        alertController.addAction(UIAlertAction(title: L10n.save, style: .default) { _ in
            subject.send(alertController.textFields?.first?.text ?? "")
            subject.send(completion: .finished)
        })
        alertController.addAction(UIAlertAction(title: L10n.cancel, style: .cancel))
        viewController.present(alertController, animated: true, completion: nil)
    }
}
