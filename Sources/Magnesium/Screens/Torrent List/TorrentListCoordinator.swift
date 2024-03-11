import Combine
import CommonModels
import Coordinator
import UIKit

final class TorrentListCoordinator: NSObject, Coordinator {
    private let viewModel: AnyTorrentListViewModel
    private let session: Session
    private let viewController: TorrentListViewController<AnyTorrentListViewModel>
    private let eventSubject = PassthroughSubject<TorrentListCoordinatorEvent, Never>()
    private var previewCoordinatorMap = [TorrentListItem: TorrentDetailCoordinator]()
    private lazy var addTorrentFlow = AddTorrentFlow(viewController: viewController, session: session)
    let viewModelEventPublisher: AnyPublisher<TorrentListViewModelEvent, Never>
    var cancellables = Set<AnyCancellable>()
    var childCoordinators = [AnyHashable: AnyCoordinator]()

    var presentable: Presentable {
        viewController
    }

    var eventPublisher: AnyPublisher<TorrentListCoordinatorEvent, Never> {
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
        viewModelEventPublisher = viewModel.eventPublisher
        super.init()
        viewController.delegate = self
    }

    func send(_ event: TorrentListViewModelEvent) {
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
        let alert = Alert(
            title: L10n.Action.addTorrent,
            message: L10n.AddTorrent.addMethodPrompt,
            style: .actionSheet(source),
            actions: [
                .init(title: L10n.AddTorrent.addLink, style: .default) {
                    self.showAddLink(subject: linkSubject)
                },
                .init(title: L10n.AddTorrent.addFile, style: .default) {
                    self.showAddFile()
                },
                .cancel,
            ]
        )
        showAlert(alert)
    }

    // internal for testing
    func showAddLink(subject: PassthroughSubject<String, Never>) {
        let alertController = UIAlertController(
            title: L10n.AddTorrent.enterURL,
            message: L10n.AddTorrent.addLinkHint,
            preferredStyle: .alert
        )
        alertController.addTextField { textField in
            textField.textContentType = .URL
            textField.placeholder = "magnet:?xt=urn:btih:c12fe1c06bba254a9dc9f519b335aa7c1367a88a"
        }
        alertController.addAction(.init(title: L10n.Action.add, style: .default) { _ in
            subject.send(alertController.textFields?.first?.text ?? "")
            subject.send(completion: .finished)
        })
        alertController.addAction(.init(title: L10n.Action.cancel, style: .cancel))
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
            title: L10n.Action.moveDownloadFolder,
            message: nil,
            preferredStyle: .alert
        )
        alertController.addTextField { textField in
            textField.textContentType = .URL
            textField.placeholder = "/downloads"
            textField.text = currentPath
        }
        alertController.addAction(.init(title: L10n.Action.save, style: .default) { _ in
            subject.send(alertController.textFields?.first?.text ?? "")
            subject.send(completion: .finished)
        })
        alertController.addAction(.init(title: L10n.Action.cancel, style: .cancel))
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
    func preview(for item: TorrentListItem) -> UIViewController? {
        guard let viewModel = viewModel.values.detailViewModel(item) else { return nil }
        let coordinator = TorrentDetailCoordinator(viewModel: viewModel)
        addChildCoordinator(coordinator) { _, _ in }
        previewCoordinatorMap[item] = coordinator
        return coordinator.presentable.viewController
    }

    func commitPreview(for item: TorrentListItem) {
        guard let coordinator = previewCoordinatorMap[item] else { return }
        previewCoordinatorMap.removeValue(forKey: item)
        eventSubject.send(.commitDetail(coordinator: coordinator))
        removeChildCoordinator(coordinator)
    }

    func willDismissPreview(for item: TorrentListItem) {
        DispatchQueue.main.async { [weak self] in
            self?.previewCoordinatorMap.removeValue(forKey: item)
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
					let client = Current.deluge(settings.url, keychain.password, keychain.basicAuthentication)
            let viewModel = StandardTorrentListViewModel(
                implementation: .deluge(.init(client: client)),
                server: server
            )
            return AnyTorrentListViewModel(viewModel)
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
            return AnyTorrentListViewModel(viewModel)
        }
    }
}
