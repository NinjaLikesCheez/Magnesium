import Combine
import Coordinator
import LinkPresentation
import Preferences
import UIKit

enum TorrentListCoordinatorEvent {
    case showDetail(viewModel: AnyTorrentDetailViewModel)
    case commitDetail(coordinator: TorrentDetailCoordinator<AnyTorrentDetailViewModel>)
    case showSettings
    case torrentsUpdated(hashes: [String])
}

final class TorrentListCoordinator: NSObject, Coordinator, AlertPresenter {
    private let viewModel: AnyTorrentListViewModel
    private let session: Session
    private let viewController: TorrentListViewController<AnyTorrentListViewModel>
    private let eventSubject = PassthroughSubject<TorrentListCoordinatorEvent, Never>()
    private var previewCoordinatorMap = [Int: TorrentDetailCoordinator<AnyTorrentDetailViewModel>]()
    private lazy var addTorrentFlow = AddTorrentFlow(viewController: viewController, session: session)
    let receivedEvents: AnyPublisher<TorrentListEvent, Never>
    var cancellables = Set<AnyCancellable>()
    var childCoordinators = [AnyHashable: AnyCoordinator]()

    var presentable: Presentable {
        viewController
    }

    var events: AnyPublisher<TorrentListCoordinatorEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    init(viewModel: AnyTorrentListViewModel, session: Session) {
        self.viewModel = viewModel
        self.session = session
        viewController = TorrentListViewController(viewModel: viewModel)
        receivedEvents = viewModel.events
        super.init()
        viewController.provider = self
    }

    func handle(_ event: TorrentListEvent) {
        switch event {
        case let .alert(alert):
            showAlert(alert)
        case let .activities(activities, torrents, source):
            showActivities(activities, torrents: torrents, source: source)
        case let .add(source, linkSubject):
            showAdd(from: source, linkSubject: linkSubject)
        case let .filter(source, labels):
            showFilter(from: source, labels: labels)
        case let .detail(viewModel):
            eventSubject.send(.showDetail(viewModel: viewModel))
        case .settings:
            eventSubject.send(.showSettings)
        case let .moveDownloadFolder(currentPath, subject):
            showMoveDownloadFolder(currentPath: currentPath, subject: subject)
        case let .torrentsUpdated(hashes):
            eventSubject.send(.torrentsUpdated(hashes: hashes))
        }
    }

    private func showActivities(_ activities: [Activity], torrents: [StandardTorrent], source: PopoverSource) {
        let activityController = UIActivityViewController(
            activityItems: [ActivityMetadataItem(metadata: LPLinkMetadata(torrents: torrents))],
            applicationActivities: activities.map { $0.createUIActivity() }
        )
        activityController.configure(popoverSource: source)
        viewController.present(activityController, animated: true)
    }

    private func showAdd(from source: PopoverSource, linkSubject: PassthroughSubject<String, Never>) {
        let alert = Alert(title: L10n.addTorrent, message: L10n.addTorrentMethodPrompt, style: .actionSheet(source)) {
            AlertAction(title: L10n.addTorrentMethodLink, style: .default) {
                self.showAddLink(subject: linkSubject)
            }

            AlertAction(title: L10n.addTorrentMethodFile, style: .default) {
                self.showAddFile()
            }

            AlertAction.cancel
        }
        showAlert(alert)
    }

    // internal for testing
    func showAddLink(subject: PassthroughSubject<String, Never>) {
        let alertController = UIAlertController(
            title: L10n.addTorrentLinkAlertTitle,
            message: L10n.addTorrentLinkAlertMessage,
            preferredStyle: .alert
        )
        alertController.addTextField { textField in
            textField.textContentType = .URL
            textField.placeholder = "magnet:?xt=urn:btih:c12fe1c06bba254a9dc9f519b335aa7c1367a88a"
        }
        alertController.addAction(UIAlertAction(title: L10n.add, style: .default) { _ in
            subject.send(alertController.textFields?.first?.text ?? "")
            subject.send(completion: .finished)
        })
        alertController.addAction(UIAlertAction(title: L10n.cancel, style: .cancel))
        viewController.present(alertController, animated: true, completion: nil)
    }

    // internal for testing
    func showAddFile() {
        let documentPicker = UIDocumentPickerViewController(documentTypes: ["public.torrent"], in: .open)
        documentPicker.delegate = self
        viewController.present(documentPicker, animated: true, completion: nil)
    }

    private func showFilter(from source: PopoverSource, labels: CurrentValueSubject<[StandardLabel], Never>) {
        let coordinator = FilterCoordinator(labels: labels)
        addChildCoordinator(coordinator) { [weak self] coordinator, event in
            self?.handle(event, from: coordinator)
        }

        let viewController = coordinator.presentable.viewController
        viewController.modalPresentationStyle = .popover
        viewController.configure(popoverSource: source)
        self.viewController.present(viewController, animated: true)
    }

    // internal for testing
    func handle<C: Coordinator>(_ event: FilterCoordinatorEvent, from coordinator: C) {
        switch event {
        case .complete:
            coordinator.presentable.viewController.dismiss(animated: true)
        }
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

extension TorrentListCoordinator: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        addTorrentFlow.add(type: .file(url))
    }
}

extension TorrentListCoordinator: TorrentListViewProvider {
    func previewForItem(at index: Int) -> UIViewController? {
        guard let viewModel = viewModel.detailViewModelForItem(at: index) else { return nil }
        let coordinator = TorrentDetailCoordinator(viewModel: viewModel)
        addChildCoordinator(coordinator) { _, _ in }
        previewCoordinatorMap[index] = coordinator
        return coordinator.presentable.viewController
    }

    func contextMenuForItem(at index: Int) -> UIMenu? {
        viewModel.contextMenuForItem(at: index)
    }

    func commitPreviewForItem(at index: Int) {
        guard let coordinator = previewCoordinatorMap[index] else { return }
        previewCoordinatorMap.removeValue(forKey: index)
        eventSubject.send(.commitDetail(coordinator: coordinator))
        removeChildCoordinator(coordinator)
    }

    func didDismissPreviewForItem(at index: Int) {
        DispatchQueue.main.async { [weak self] in
            self?.previewCoordinatorMap.removeValue(forKey: index)
        }
    }

    func leadingSwipeActionsConfigurationForItem(at index: Int, source: PopoverSource) -> UISwipeActionsConfiguration? {
        let configuration = viewModel.leadingSwipeActionsConfigurationForItem(at: index, source: source)
        return configuration?.createUISwipeActionsConfiguration()
    }

    func trailingSwipeActionsConfigurationForItem(
        at index: Int,
        source: PopoverSource
    ) -> UISwipeActionsConfiguration? {
        let configuration = viewModel.trailingSwipeActionsConfigurationForItem(at: index, source: source)
        return configuration?.createUISwipeActionsConfiguration()
    }
}
