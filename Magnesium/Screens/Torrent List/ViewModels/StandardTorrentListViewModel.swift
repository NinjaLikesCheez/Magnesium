import Combine
import Preferences
import UIKit
import ViewModel

protocol StandardTorrentListViewModelImplementation {
    associatedtype Torrent: StandardTorrent
    associatedtype Label: StandardLabel
    var updated: AnyPublisher<([Torrent], [Label]), Never> { get }
    func refresh() -> AnyPublisher<([Torrent], [Label]), Error>
    func detailViewModel(
        for torrent: CurrentValueSubject<Torrent, Never>,
        labels: CurrentValueSubject<[Label], Never>
    ) -> AnyTorrentDetailViewModel
    func addLink(_ url: String) -> AnyPublisher<(String, String), Never>
    func pause(_ torrents: [Torrent]) -> AnyPublisher<Void, Error>
    func resume(_ torrents: [Torrent]) -> AnyPublisher<Void, Error>
    func remove(_ torrents: [Torrent], removeData: Bool) -> AnyPublisher<Void, Error>
    func verify(_ torrents: [Torrent]) -> AnyPublisher<Void, Error>
    func setLabel(_ label: Label, for torrents: [Torrent]) -> AnyPublisher<Void, Error>
    func updateTrackers(for torrents: [Torrent]) -> AnyPublisher<Void, Error>
    func moveDownloadFolder(for torrents: [Torrent], to path: String) -> AnyPublisher<Void, Error>
}

// swiftlint:disable:next line_length
final class StandardTorrentListViewModel<Implementation: StandardTorrentListViewModelImplementation>: ViewModel, TorrentListProvider {
    typealias Torrent = Implementation.Torrent
    typealias Label = Implementation.Label

    private let implementation: Implementation
    private let torrents: TorrentMapper<String, Torrent>
    private let labels = CurrentValueSubject<[Label], Never>([])
    private let isLoadingSubject = CurrentValueSubject<Bool, Never>(true)
    private let isEditingSubject = CurrentValueSubject<Bool, Never>(false)
    private let multiSelectCountSubject = CurrentValueSubject<Int, Never>(0)
    private let eventSubject = PassthroughSubject<TorrentListEvent, Never>()
    private let querySubject = CurrentValueSubject<String?, Never>(nil)
    private var autoRefreshTimer: Timer?
    let state: TorrentListViewState
    var cancellables = Set<AnyCancellable>()

    var events: AnyPublisher<TorrentListEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    init(implementation: Implementation, server: Server) {
        torrents = TorrentMapper(query: querySubject)
        self.implementation = implementation

        let title = isEditingSubject
            .combineLatest(multiSelectCountSubject)
            .map { isEditing, count in
                isEditing ? L10n.selectedCount(count) : server.name
            }
            .ui()
            .eraseToAnyPublisher()
        let items = torrents.values
            .map { $0.map { TorrentListItem(torrent: $0) } }
            .ui()
            .eraseToAnyPublisher()
        let hasActiveFilters = Current.preferences.valuePublisher(for: .filterOptions)
            .map { $0 != FilterOptions() }
            .ui()
            .eraseToAnyPublisher()
        let totalDownloadSpeed = torrents.allValues
            .map { $0.reduce(0) { $0 + $1.value.downloadRate } }
            .map { L10n.torrentDownloadSpeed(Formatters.bytes.string(fromByteCount: $0)) }
            .ui()
            .eraseToAnyPublisher()
        let totalUploadSpeed = torrents.allValues
            .map { $0.reduce(0) { $0 + $1.value.uploadRate } }
            .map { L10n.torrentUploadSpeed(Formatters.bytes.string(fromByteCount: $0)) }
            .ui()
            .eraseToAnyPublisher()
        state = TorrentListViewState(
            title: title,
            items: items,
            isLoading: isLoadingSubject.removeDuplicates().ui().eraseToAnyPublisher(),
            hasActiveFilters: hasActiveFilters,
            editActionsEnabled: multiSelectCountSubject.map { $0 > 0 }.ui().eraseToAnyPublisher(),
            totalDownloadSpeed: totalDownloadSpeed,
            totalUploadSpeed: totalUploadSpeed
        )

        refresh()
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)

        Current.preferences.valuePublisher(for: .autoRefreshInterval)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] value in
                self?.configureAutoRefreshTimer(interval: value)
            })
            .store(in: &cancellables)

        implementation.updated
            .sink { [weak self] update in
                self?.labels.send(update.1)
                self?.torrents.update(with: update.0.map { ($0.hash, $0) })
            }
            .store(in: &cancellables)

        torrents.values
            .ui()
            .sink { [weak self] torrents in
                self?.eventSubject.send(.torrentsUpdated(hashes: torrents.map(\.value.hash)))
            }
            .store(in: &cancellables)
    }

    deinit {
        autoRefreshTimer?.invalidate()
    }

    // swiftlint:disable:next cyclomatic_complexity
    func handle(_ event: TorrentListViewEvent) {
        switch event {
        case .refresh:
            refresh()
                .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
                .store(in: &cancellables)

        case let .addSelected(source):
            let linkSubject = PassthroughSubject<String, Never>()
            linkSubject
                .sink { [weak self] in self?.addLink($0) }
                .store(in: &cancellables)
            eventSubject.send(.add(source: source, linkSubject: linkSubject))

        case let .filterSelected(source):
            let mappedLabels = CurrentValueSubject<[StandardLabel], Never>(labels.value)
            labels.sink { [weak mappedLabels] in mappedLabels?.send($0) }.store(in: &cancellables)
            eventSubject.send(.filter(source: source, labels: mappedLabels))

        case let .itemSelected(index):
            let subject = torrents.subject(at: index)
            let viewModel = implementation.detailViewModel(for: subject, labels: labels)
            eventSubject.send(.detail(viewModel: viewModel))

        case .settingsSelected:
            eventSubject.send(.settings)

        case let .search(query):
            querySubject.send(query)

        case let .resumeSelected(indices):
            resume(indices.map { torrents.subject(at: $0).value })

        case let .pauseSelected(indices):
            pause(indices.map { torrents.subject(at: $0).value })

        case let .removeSelected(indices, source):
            presentRemoveOptions(for: indices.map { torrents.subject(at: $0).value }, from: source)

        case let .moreOptionsSelected(indices, source):
            presentActivities(for: indices.map { torrents.subject(at: $0).value }, source: source)

        case .didBeginEditing:
            isEditingSubject.send(true)

        case .didEndEditing:
            isEditingSubject.send(false)

        case let .multiSelectUpdated(indices):
            multiSelectCountSubject.send(indices.count)
        }
    }

    // internal for testing
    func addLink(_ url: String) {
        implementation.addLink(url)
            .ui()
            .sink { [weak self] title, message in
                self?.showError(title: title, message: message)
            }
            .store(in: &cancellables)
    }

    private func pause(_ torrents: [Torrent]) {
        implementation.pause(torrents)
            .handleEvents(receiveCompletion: { [weak self] completion in
                guard let strongSelf = self, case .finished = completion else { return }
                strongSelf.implementation.refresh()
                    .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
                    .store(in: &strongSelf.cancellables)
            })
            .ui()
            .sink(receiveCompletion: { [weak self] completion in
                guard case let .failure(error) = completion else { return }
                self?.showError(title: L10n.pauseError, message: error.localizedDescription)
            }, receiveValue: { _ in })
            .store(in: &cancellables)
    }

    private func resume(_ torrents: [Torrent]) {
        implementation.resume(torrents)
            .handleEvents(receiveCompletion: { [weak self] completion in
                guard let strongSelf = self, case .finished = completion else { return }
                strongSelf.implementation.refresh()
                    .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
                    .store(in: &strongSelf.cancellables)
            })
            .ui()
            .sink(receiveCompletion: { [weak self] completion in
                guard case let .failure(error) = completion else { return }
                self?.showError(title: L10n.resumeError, message: error.localizedDescription)
            }, receiveValue: { _ in })
            .store(in: &cancellables)
    }

    private func remove(_ torrents: [Torrent], removeData: Bool) {
        implementation.remove(torrents, removeData: removeData)
            .handleEvents(receiveCompletion: { [weak self] completion in
                guard let strongSelf = self, case .finished = completion else { return }
                strongSelf.implementation.refresh()
                    .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
                    .store(in: &strongSelf.cancellables)
            })
            .ui()
            .sink(receiveCompletion: { [weak self] completion in
                guard case let .failure(error) = completion else { return }
                self?.showError(title: L10n.removeError, message: error.localizedDescription)
            }, receiveValue: { _ in })
            .store(in: &cancellables)
    }

    private func setLabel(for torrents: [Torrent], label: Label) {
        implementation.setLabel(label, for: torrents)
            .handleEvents(receiveCompletion: { [weak self] completion in
                guard let strongSelf = self, case .finished = completion else { return }
                strongSelf.implementation.refresh()
                    .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
                    .store(in: &strongSelf.cancellables)
            })
            .ui()
            .sink(receiveCompletion: { [weak self] completion in
                guard case let .failure(error) = completion else { return }
                self?.showError(title: L10n.setLabelError, message: error.localizedDescription)
            }, receiveValue: { _ in })
            .store(in: &cancellables)
    }

    private func verify(_ torrents: [Torrent]) {
        implementation.verify(torrents)
            .handleEvents(receiveCompletion: { [weak self] completion in
                guard let strongSelf = self, case .finished = completion else { return }
                strongSelf.implementation.refresh()
                    .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
                    .store(in: &strongSelf.cancellables)
            })
            .ui()
            .sink(receiveCompletion: { [weak self] completion in
                guard case let .failure(error) = completion else { return }
                self?.showError(title: L10n.verifyFilesError, message: error.localizedDescription)
            }, receiveValue: { _ in })
            .store(in: &cancellables)
    }

    private func updateTrackers(for torrents: [Torrent]) {
        implementation.updateTrackers(for: torrents)
            .handleEvents(receiveCompletion: { [weak self] completion in
                guard let strongSelf = self, case .finished = completion else { return }
                strongSelf.implementation.refresh()
                    .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
                    .store(in: &strongSelf.cancellables)
            })
            .ui()
            .sink(receiveCompletion: { [weak self] completion in
                guard case let .failure(error) = completion else { return }
                self?.showError(title: L10n.updateTrackersError, message: error.localizedDescription)
                }, receiveValue: { _ in })
            .store(in: &cancellables)
    }

    private func moveDownloadFolder(for torrents: [Torrent], to path: String) {
        implementation.moveDownloadFolder(for: torrents, to: path)
            .handleEvents(receiveCompletion: { [weak self] completion in
                guard let strongSelf = self, case .finished = completion else { return }
                strongSelf.implementation.refresh()
                    .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
                    .store(in: &strongSelf.cancellables)
            })
            .ui()
            .sink(receiveCompletion: { [weak self] completion in
                guard case let .failure(error) = completion else { return }
                self?.showError(title: L10n.moveDownloadFolderError, message: error.localizedDescription)
            }, receiveValue: { _ in })
            .store(in: &cancellables)
    }

    private func presentRemoveOptions(for torrents: [Torrent], from source: PopoverSource) {
        let message = torrents.count == 1 ? torrents[0].name : L10n.torrentCount(torrents.count)
        var alert = Alert(title: L10n.remove, message: message, style: .actionSheet(source))
        alert.addAction(AlertAction(title: L10n.removeTorrentOptionKeepData, style: .default) {
            self.remove(torrents, removeData: false)
        })
        alert.addAction(AlertAction(title: L10n.removeTorrentOptionRemoveData, style: .destructive) {
            self.remove(torrents, removeData: true)
        })
        alert.addAction(.cancel)
        eventSubject.send(.alert(alert))
    }

    private func presentLabelSelection(for torrents: [Torrent], from source: PopoverSource) {
        let message = torrents.count == 1 ? torrents[0].name : L10n.torrentCount(torrents.count)
        var alert = Alert(title: L10n.setLabel, message: message, style: .actionSheet(source))
        for label in labels.value {
            alert.addAction(AlertAction(title: label.displayName, style: .default) {
                self.setLabel(for: torrents, label: label)
            })
        }
        alert.addAction(.cancel)
        eventSubject.send(.alert(alert))
    }

    private func presentActivities(for torrents: [Torrent], source: PopoverSource) {
        var activities = [Activity]()

        if !labels.value.isEmpty {
            activities.append(.setLabel {
                self.presentLabelSelection(for: torrents, from: source)
            })
        }

        activities.append(.verifyFiles {
            self.verify(torrents)
        })

        activities.append(.moveDownloadFolder {
            let subject = PassthroughSubject<String, Never>()
            subject
                .sink { [weak self] path in
                    self?.moveDownloadFolder(for: torrents, to: path)
                }
                .store(in: &self.cancellables)
            let currentPath = Set(torrents.map(\.downloadPath)).count == 1 ? torrents[0].downloadPath : nil
            self.eventSubject.send(.moveDownloadFolder(currentPath: currentPath, subject: subject))
        })

        activities.append(.updateTrackers {
            self.updateTrackers(for: torrents)
        })

        eventSubject.send(.activities(activities, torrents: torrents, source: source))
    }

    private func showError(title: String, message: String?) {
        var alert = Alert(
            title: title,
            message: message,
            style: .alert
        )
        alert.addAction(.ok)
        eventSubject.send(.alert(alert))
    }

    // MARK: Auto Refresh

    private func configureAutoRefreshTimer(interval: Int?) {
        autoRefreshTimer?.invalidate()
        guard let interval = interval.map({ TimeInterval($0) }), interval > 0 else { return }
        let timer = Timer(fire: Date().advanced(by: interval), interval: interval, repeats: true) { [weak self] in
            self?.refreshTimerFired($0)
        }
        RunLoop.main.add(timer, forMode: .common)
        autoRefreshTimer = timer
    }

    private func refreshTimerFired(_ timer: Timer) {
        performRefresh()
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)
    }

    private func refresh() -> AnyPublisher<Void, Error> {
        performRefresh()
            .mapError { $0 as Error }
            .ui()
            .handleEvents(receiveCompletion: { [weak self] completion in
                guard case let .failure(error) = completion else { return }
                self?.showError(title: L10n.refreshError, message: error.localizedDescription)
            })
            .eraseToAnyPublisher()
    }

    private func performRefresh() -> AnyPublisher<Void, Error> {
        isLoadingSubject.send(true)
        return implementation.refresh()
            .handleEvents(receiveOutput: { [weak self] update in
                self?.labels.send(update.1)
                self?.torrents.update(with: update.0.map { ($0.hash, $0) })
                self?.isLoadingSubject.send(false)
            }, receiveCompletion: { [weak self] _ in
                self?.isLoadingSubject.send(false)
            })
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    // MARK: TorrentListPreviewProvider

    func detailViewModelForItem(at index: Int) -> AnyTorrentDetailViewModel? {
        let subject = torrents.subject(at: index)
        return implementation.detailViewModel(for: subject, labels: labels)
    }

    func contextMenuForItem(at index: Int) -> UIMenu? {
        let torrent = torrents.subject(at: index).value
        var actions = [UIMenuElement]()

        if torrent.isActive {
            actions.append(UIAction(title: L10n.pause, image: UIImage(systemName: "pause")) { [weak self] _ in
                self?.pause([torrent])
            })
        } else {
            actions.append(UIAction(title: L10n.resume, image: UIImage(systemName: "play")) { [weak self] _ in
                self?.resume([torrent])
            })
        }

        if !labels.value.isEmpty {
            let children = labels.value.map { label in
                UIAction(title: label.displayName) { [weak self] _ in
                    self?.setLabel(for: [torrent], label: label)
                }
            }
            actions.append(UIMenu(title: L10n.setLabel, image: UIImage(systemName: "tag"), children: children))
        }

        actions.append(UIAction(title: L10n.verifyFiles, image: UIImage(systemName: "tray.full")) { [weak self] _ in
            self?.verify([torrent])
        })

        actions.append(UIAction(
            title: L10n.moveDownloadFolder,
            image: UIImage(systemName: "tray.and.arrow.down"),
            handler: { [weak self] _ in
                guard let strongSelf = self else { return }
                let subject = PassthroughSubject<String, Never>()
                subject
                    .sink { [weak self] path in
                        self?.moveDownloadFolder(for: [torrent], to: path)
                    }
                    .store(in: &strongSelf.cancellables)
                strongSelf.eventSubject.send(.moveDownloadFolder(
                    currentPath: torrent.downloadPath,
                    subject: subject
                ))
            }
        ))

        actions.append(UIAction(
            title: L10n.updateTrackers,
            image: UIImage(systemName: "arrow.clockwise"),
            handler: { [weak self] _ in
                self?.updateTrackers(for: [torrent])
            }
        ))
        actions.append(UIMenu(
            title: L10n.remove,
            image: UIImage(systemName: "trash"),
            options: .destructive,
            children: [
                UIAction(
                    title: L10n.removeTorrentOptionKeepData,
                    image: UIImage(systemName: "trash"),
                    handler: { [weak self] _ in
                        self?.remove([torrent], removeData: false)
                    }
                ),
                UIAction(
                    title: L10n.removeTorrentOptionRemoveData,
                    image: UIImage(systemName: "trash"),
                    attributes: .destructive,
                    handler: { [weak self] _ in
                        self?.remove([torrent], removeData: true)
                    }
                ),
            ]
        ))

        return UIMenu(title: "", children: actions)
    }

    func leadingSwipeActionsConfigurationForItem(at index: Int, source: PopoverSource) -> SwipeActionsConfiguration? {
        let torrent = torrents.subject(at: index).value
        if torrent.isActive {
            return SwipeActionsConfiguration(actions: [
                SwipeAction(
                    image: UIImage(systemName: "pause.fill"),
                    backgroundColor: .systemBlue,
                    style: .normal,
                    handler: {
                        self.pause([torrent])
                    }
                ),
            ])
        } else {
            return SwipeActionsConfiguration(actions: [
                SwipeAction(
                    image: UIImage(systemName: "play.fill"),
                    backgroundColor: .systemBlue,
                    style: .normal,
                    handler: {
                        self.resume([torrent])
                    }
                ),
            ])
        }
    }

    func trailingSwipeActionsConfigurationForItem(
        at index: Int,
        source: PopoverSource
    ) -> SwipeActionsConfiguration? {
        let torrent = torrents.subject(at: index).value
        return SwipeActionsConfiguration(actions: [
            SwipeAction(
                image: UIImage(systemName: "trash.fill"),
                style: .destructive,
                handler: {
                    self.presentRemoveOptions(for: [torrent], from: source)
                }
            ),
            SwipeAction(
                image: UIImage(systemName: "ellipsis.circle.fill"),
                backgroundColor: .systemGray,
                handler: {
                    self.presentActivities(for: [torrent], source: source)
                }
            ),
        ])
    }
}
