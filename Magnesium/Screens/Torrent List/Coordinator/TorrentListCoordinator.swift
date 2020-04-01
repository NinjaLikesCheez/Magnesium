import Combine
import CommonModels
import Coordinator
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
    let viewModelEvents: AnyPublisher<TorrentListViewModelEvent, Never>
    var cancellables = Set<AnyCancellable>()
    var childCoordinators = [AnyHashable: AnyCoordinator]()

    var presentable: Presentable {
        viewController
    }

    var events: AnyPublisher<TorrentListCoordinatorEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    convenience init?(server: Server, session: Session) {
        guard let viewModel = Self.decode(server: server) else { return nil }
        self.init(viewModel: viewModel, session: session)
    }

    init?(viewModel: AnyTorrentListViewModel, session: Session) {
        self.viewModel = viewModel
        self.session = session
        viewController = .init(viewModel: viewModel)
        viewModelEvents = viewModel.events
        super.init()
        viewController.delegate = self
    }

    func receive(_ event: TorrentListViewModelEvent) {
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
            activityItems: [ActivityMetadataItem(metadata: .init(torrents: torrents))],
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
        alertController.addAction(.init(title: L10n.add, style: .default) { _ in
            subject.send(alertController.textFields?.first?.text ?? "")
            subject.send(completion: .finished)
        })
        alertController.addAction(.init(title: L10n.cancel, style: .cancel))
        viewController.present(alertController, animated: true, completion: nil)
    }

    // internal for testing
    func showAddFile() {
        let documentPicker = UIDocumentPickerViewController(documentTypes: ["public.torrent"], in: .open)
        documentPicker.delegate = self
        viewController.present(documentPicker, animated: true, completion: nil)
    }

    private func showFilter(from source: PopoverSource, labels: AnyPublisher<[StandardLabel], Never>) {
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
        alertController.addAction(.init(title: L10n.save, style: .default) { _ in
            subject.send(alertController.textFields?.first?.text ?? "")
            subject.send(completion: .finished)
        })
        alertController.addAction(.init(title: L10n.cancel, style: .cancel))
        viewController.present(alertController, animated: true, completion: nil)
    }
}

extension TorrentListCoordinator: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        addTorrentFlow.add(type: .file(url))
    }
}

extension TorrentListCoordinator: TorrentListViewDelegate {
    func previewForItem(at index: Int) -> UIViewController? {
        guard let viewModel = viewModel.values.detailViewModel(index) else { return nil }
        let coordinator = TorrentDetailCoordinator(viewModel: viewModel)
        addChildCoordinator(coordinator) { _, _ in }
        previewCoordinatorMap[index] = coordinator
        return coordinator.presentable.viewController
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
}

private extension TorrentListCoordinator {
    static func decode(server: Server) -> AnyTorrentListViewModel? {
        switch server.type {
        case .deluge:
            let decoder = JSONDecoder()
            guard let settings = try? decoder.decode(DelugeServerSettings.self, from: server.data),
                let keychainData = server.keychainData,
                let keychain = try? decoder.decode(DelugeKeychainData.self, from: keychainData)
            else {
                return nil
            }
            let client = Current.deluge(settings.url, keychain.password)
            let viewModel = StandardTorrentListViewModel(
                implementation: .deluge(.init(client: client)),
                server: server
            )
            return .init(viewModel)
        case .transmission:
            let decoder = JSONDecoder()
            guard let settings = try? decoder.decode(TransmissionServerSettings.self, from: server.data),
                let keychainData = server.keychainData,
                let keychain = try? decoder.decode(TransmissionKeychainData.self, from: keychainData)
            else {
                return nil
            }
            let client = Current.transmission(settings.url, settings.username, keychain.password)
            let viewModel = StandardTorrentListViewModel(
                implementation: .transmission(.init(client: client)),
                server: server
            )
            return .init(viewModel)
        }
    }
}
