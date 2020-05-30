import Combine
import CommonModels
import Coordinator
import UIKit
import ViewModel

enum TorrentDetailCoordinatorEvent {
    case complete
}

final class TorrentDetailCoordinator: Coordinator {
    private let viewController: TorrentDetailViewController<AnyTorrentDetailViewModel>
    private let eventSubject = PassthroughSubject<TorrentDetailCoordinatorEvent, Never>()
    let viewModelEventPublisher: AnyPublisher<TorrentDetailViewModelEvent, Never>
    var cancellables = Set<AnyCancellable>()
    var childCoordinators = [AnyHashable: AnyCoordinator]()

    var presentable: Presentable {
        viewController
    }

    var eventPublisher: AnyPublisher<TorrentDetailCoordinatorEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    init(viewModel: AnyTorrentDetailViewModel) {
        viewController = .init(viewModel: viewModel)
        viewModelEventPublisher = viewModel.eventPublisher
    }

    func send(_ event: TorrentDetailViewModelEvent) {
        switch event {
        case .complete:
            eventSubject.send(.complete)
        case let .alert(alert):
            showAlert(alert)
        case let .activities(activities, torrent, source):
            showActivities(activities, torrent: torrent, source: source)
        case let .moveDownloadFolder(currentPath, subject):
            showMoveDownloadFolder(currentPath: currentPath, subject: subject)
        }
    }

    private func showActivities(_ activities: [Activity], torrent: StandardTorrent, source: PopoverSource) {
        let activityController = UIActivityViewController(
            activityItems: [ActivityMetadataItem(metadata: .init(torrents: [torrent]))],
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
        alertController.addAction(.init(title: L10n.save, style: .default) { _ in
            subject.send(alertController.textFields?.first?.text ?? "")
            subject.send(completion: .finished)
        })
        alertController.addAction(.init(title: L10n.cancel, style: .cancel))
        viewController.present(alertController, animated: true, completion: nil)
    }
}
