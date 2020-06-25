import Combine
import CommonModels
import Preferences
import UIKit
import ViewModel

final class StandardTorrentListViewModel: ViewModel {
    private let implementation: StandardTorrentListImplementation
    private let torrentMapper: TorrentMapper
    private let labelsSubject = CurrentValueSubject<[StandardLabel], Never>([])
    private let isLoadingSubject = CurrentValueSubject<Bool, Never>(true)
    private let isEditingSubject = CurrentValueSubject<Bool, Never>(false)
    private let multiSelectCountSubject = CurrentValueSubject<Int, Never>(0)
    private let eventSubject = PassthroughSubject<TorrentListViewModelEvent, Never>()
    private let querySubject = CurrentValueSubject<String?, Never>(nil)
    private var autoRefreshTimer: Timer?
    private var _values: TorrentListViewValues!
    var cancellables = Set<AnyCancellable>()

    var values: TorrentListViewValues {
        _values
    }

    var eventPublisher: AnyPublisher<TorrentListViewModelEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    init(implementation: StandardTorrentListImplementation, server: Server) {
        torrentMapper = TorrentMapper(querySubject: querySubject)
        self.implementation = implementation

        let title = isEditingSubject
            .combineLatest(multiSelectCountSubject)
            .map { isEditing, count in
                isEditing ? L10n.selectedCount(count) : server.name
            }
            .ui()

        let items = torrentMapper.valuesPublisher
            .map { $0.map { TorrentListItem(torrentSubject: $0) } }
            .ui()

        let hasActiveFilters = Current.preferences.valuePublisher(for: .filterOptions)
            .map { $0 != FilterOptions() }
            .ui()

        let totalDownloadSpeed = torrentMapper.allValuesPublisher
            .map { $0.reduce(0) { $0 + $1.value.downloadRate } }
            .map { L10n.torrentDownloadSpeed(Formatters.bytes.string(fromByteCount: $0)) }
            .ui()

        let totalUploadSpeed = torrentMapper.allValuesPublisher
            .map { $0.reduce(0) { $0 + $1.value.uploadRate } }
            .map { L10n.torrentUploadSpeed(Formatters.bytes.string(fromByteCount: $0)) }
            .ui()

        let status = Publishers.CombineLatest(totalDownloadSpeed, totalUploadSpeed)
            .map { "\($0) \($1)" }
            .ui()

        _values = .init(
            title: title,
            items: items,
            isLoading: isLoadingSubject.removeDuplicates().ui(),
            isEditing: isEditingSubject.removeDuplicates().ui(),
            hasActiveFilters: hasActiveFilters,
            editActionsEnabled: multiSelectCountSubject.map { $0 > 0 }.ui(),
            status: status,
            detailViewModel: { [weak self] in
                self?.detailViewModel(for: $0)
            },
            contextMenu: { [weak self] in
                self?.contextMenu(for: $0)
            },
            leadingSwipeActionsConfiguration: { [weak self] in
                self?.leadingSwipeActionsConfiguration(for: $0, source: $1)
            },
            trailingSwipeActionsConfiguration: { [weak self] in
                self?.trailingSwipeActionsConfiguration(for: $0, source: $1)
            }
        )

        refresh()
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)

        Current.preferences.valuePublisher(for: .autoRefreshInterval)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] value in
                self?.configureAutoRefreshTimer(interval: value)
            })
            .store(in: &cancellables)

        implementation.updated.sink { [weak self] update in
            self?.labelsSubject.send(update.1)
            self?.torrentMapper.update(with: update.0)
        }.store(in: &cancellables)

        torrentMapper.valuesPublisher
            .ui()
            .sink { [weak self] torrents in
                self?.eventSubject.send(.torrentsUpdated(hashes: torrents.map(\.value.hash)))
            }
            .store(in: &cancellables)
    }

    deinit {
        autoRefreshTimer?.invalidate()
    }

    // MARK: View Events

    // swiftlint:disable:next cyclomatic_complexity
    func send(_ event: TorrentListViewEvent) {
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
            let mappedLabels = CurrentValueSubject<[StandardLabel], Never>(labelsSubject.value)
            labelsSubject.sink { [weak mappedLabels] in mappedLabels?.send($0) }.store(in: &cancellables)
            eventSubject.send(.filter(source: source, labels: mappedLabels.eraseToAnyPublisher()))

        case let .itemSelected(index):
            let torrent = torrentMapper.values[index]
            let viewModel = implementation.detailViewModel(torrent, labelsSubject)
            eventSubject.send(.detail(viewModel: viewModel))

        case .settingsSelected:
            eventSubject.send(.settings)

        case let .search(query):
            querySubject.send(query)

        case let .resumeSelected(indices):
            resume(indices.map { torrentMapper.values[$0].value })

        case let .pauseSelected(indices):
            pause(indices.map { torrentMapper.values[$0].value })

        case let .removeSelected(indices, source):
            presentRemoveOptions(for: indices.map { torrentMapper.values[$0].value }, from: source)

        case let .moreOptionsSelected(indices, source):
            presentActivities(for: indices.map { torrentMapper.values[$0].value }, source: source)

        case let .multiSelectUpdated(indices):
            multiSelectCountSubject.send(indices.count)

        case .editSelected:
            isEditingSubject.send(true)

        case .doneEditingSelected:
            isEditingSubject.send(false)
        }
    }

    // internal for testing
    func addLink(_ url: String) {
        implementation.addLink(url)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] in
                if case let .failure(error) = $0 {
                    self?.showError(title: error.title, message: error.message)
                }
            }, receiveValue: { _ in })
            .store(in: &cancellables)
    }

    private func pause(_ torrents: [StandardTorrent]) {
        implementation.pause(torrents)
            .append(implementation.refresh().asVoid().replaceError(with: ()).setFailureType(to: Error.self))
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                guard case let .failure(error) = completion else { return }
                self?.showError(title: L10n.pauseError, message: error.localizedDescription)
            }, receiveValue: { _ in })
            .store(in: &cancellables)
    }

    private func resume(_ torrents: [StandardTorrent]) {
        implementation.resume(torrents)
            .append(implementation.refresh().asVoid().replaceError(with: ()).setFailureType(to: Error.self))
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                guard case let .failure(error) = completion else { return }
                self?.showError(title: L10n.resumeError, message: error.localizedDescription)
            }, receiveValue: { _ in })
            .store(in: &cancellables)
    }

    private func remove(_ torrents: [StandardTorrent], removeData: Bool) {
        implementation.remove(torrents, removeData)
            .append(implementation.refresh().asVoid().replaceError(with: ()).setFailureType(to: Error.self))
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                guard case let .failure(error) = completion else { return }
                self?.showError(title: L10n.removeError, message: error.localizedDescription)
            }, receiveValue: { _ in })
            .store(in: &cancellables)
    }

    private func setLabel(for torrents: [StandardTorrent], label: StandardLabel) {
        implementation.setLabel(label, torrents)
            .append(implementation.refresh().asVoid().replaceError(with: ()).setFailureType(to: Error.self))
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                guard case let .failure(error) = completion else { return }
                self?.showError(title: L10n.setLabelError, message: error.localizedDescription)
            }, receiveValue: { _ in })
            .store(in: &cancellables)
    }

    private func verify(_ torrents: [StandardTorrent]) {
        implementation.verify(torrents)
            .append(implementation.refresh().asVoid().replaceError(with: ()).setFailureType(to: Error.self))
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                guard case let .failure(error) = completion else { return }
                self?.showError(title: L10n.verifyFilesError, message: error.localizedDescription)
            }, receiveValue: { _ in })
            .store(in: &cancellables)
    }

    private func updateTrackers(for torrents: [StandardTorrent]) {
        implementation.updateTrackers(torrents)
            .append(implementation.refresh().asVoid().replaceError(with: ()).setFailureType(to: Error.self))
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                guard case let .failure(error) = completion else { return }
                self?.showError(title: L10n.updateTrackersError, message: error.localizedDescription)
                }, receiveValue: { _ in })
            .store(in: &cancellables)
    }

    private func moveDownloadFolder(for torrents: [StandardTorrent], to path: String) {
        implementation.moveDownloadFolder(path, torrents)
            .append(implementation.refresh().asVoid().replaceError(with: ()).setFailureType(to: Error.self))
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                guard case let .failure(error) = completion else { return }
                self?.showError(title: L10n.moveDownloadFolderError, message: error.localizedDescription)
            }, receiveValue: { _ in })
            .store(in: &cancellables)
    }

    private func presentRemoveOptions(for torrents: [StandardTorrent], from source: PopoverSource) {
        let message = torrents.count == 1 ? torrents[0].name : L10n.torrentCount(torrents.count)
        eventSubject.send(.alert(.init(
            title: L10n.remove,
            message: message,
            style: .actionSheet(source),
            actions: [
                .init(title: L10n.removeTorrentOptionKeepData, style: .default) {
                    self.remove(torrents, removeData: false)
                },
                .init(title: L10n.removeTorrentOptionRemoveData, style: .destructive) {
                    self.remove(torrents, removeData: true)
                },
                .cancel,
            ]
        )))
    }

    private func presentLabelSelection(for torrents: [StandardTorrent], from source: PopoverSource) {
        let message = torrents.count == 1 ? torrents[0].name : L10n.torrentCount(torrents.count)
        let labelActions = labelsSubject.value.map { label in
            AlertAction(title: label.displayName, style: .default) {
                self.setLabel(for: torrents, label: label)
            }
        }

        eventSubject.send(.alert(.init(
            title: L10n.setLabel,
            message: message,
            style: .actionSheet(source),
            actions: labelActions + [.cancel]
        )))
    }

    private func presentActivities(for torrents: [StandardTorrent], source: PopoverSource) {
        var activities = [Activity]()

        if !labelsSubject.value.isEmpty {
            activities.append(.setLabel {
                self.presentLabelSelection(for: torrents, from: source)
            })
        }

        activities.append(.verifyFiles {
            self.verify(torrents)
        })

        activities.append(.moveDownloadFolder {
            let subject = PassthroughSubject<String, Never>()
            subject.sink { [weak self] path in
                self?.moveDownloadFolder(for: torrents, to: path)
            }.store(in: &self.cancellables)
            let currentPath = Set(torrents.map(\.downloadPath)).count == 1 ? torrents[0].downloadPath : nil
            self.eventSubject.send(.moveDownloadFolder(currentPath: currentPath, subject: subject))
        })

        activities.append(.updateTrackers {
            self.updateTrackers(for: torrents)
        })

        eventSubject.send(.activities(activities, torrents: torrents, source: source))
    }

    private func showError(title: String, message: String?) {
        eventSubject.send(.alert(.init(title: title, message: message, style: .alert, action: .ok)))
    }

    // MARK: View Functions

    private func detailViewModel(for item: TorrentListItem) -> AnyTorrentDetailViewModel? {
        guard let subject = torrentMapper.map[item.hash] else { return nil }
        return implementation.detailViewModel(subject, labelsSubject)
    }

    private func contextMenu(for item: TorrentListItem) -> Menu? {
        guard let torrent = torrentMapper.map[item.hash]?.value else { return nil }

        var items = [MenuItem]()

        if torrent.isActive {
            items.append(.action(.init(title: L10n.pause, image: UIImage(systemName: "pause")) { [weak self] in
                self?.pause([torrent])
            }))
        } else {
            items.append(.action(.init(title: L10n.resume, image: UIImage(systemName: "play")) { [weak self] in
                self?.resume([torrent])
            }))
        }

        if !labelsSubject.value.isEmpty {
            let children: [MenuItem] = labelsSubject.value.map { label in
                .action(.init(title: label.displayName) { [weak self] in
                    self?.setLabel(for: [torrent], label: label)
                })
            }
            items.append(.menu(.init(title: L10n.setLabel, image: UIImage(systemName: "tag"), children: children)))
        }

        items.append(.action(.init(title: L10n.verifyFiles, image: UIImage(systemName: "tray.full")) { [weak self] in
            self?.verify([torrent])
        }))

        items.append(.action(.init(
            title: L10n.moveDownloadFolder,
            image: UIImage(systemName: "tray.and.arrow.down"),
            handler: { [weak self] in
                guard let strongSelf = self else { return }
                let subject = PassthroughSubject<String, Never>()
                subject.sink { [weak self] path in
                    self?.moveDownloadFolder(for: [torrent], to: path)
                }.store(in: &strongSelf.cancellables)
                strongSelf.eventSubject.send(.moveDownloadFolder(
                    currentPath: torrent.downloadPath,
                    subject: subject
                ))
            }
        )))

        items.append(.action(.init(
            title: L10n.updateTrackers,
            image: UIImage(systemName: "arrow.clockwise"),
            handler: { [weak self] in
                self?.updateTrackers(for: [torrent])
            }
        )))

        items.append(.menu(.init(
            title: L10n.remove,
            image: UIImage(systemName: "trash"),
            options: [.destructive],
            children: [
                .action(.init(
                    title: L10n.removeTorrentOptionKeepData,
                    image: UIImage(systemName: "trash"),
                    handler: { [weak self] in
                        self?.remove([torrent], removeData: false)
                    }
                )),
                .action(.init(
                    title: L10n.removeTorrentOptionRemoveData,
                    image: UIImage(systemName: "trash"),
                    attributes: [.destructive],
                    handler: { [weak self] in
                        self?.remove([torrent], removeData: true)
                    }
                )),
            ]
        )))

        return Menu(children: items)
    }

    private func leadingSwipeActionsConfiguration(
        for item: TorrentListItem,
        source: PopoverSource
    ) -> SwipeActionsConfiguration? {
        guard let torrent = torrentMapper.map[item.hash]?.value else { return nil }

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

    private func trailingSwipeActionsConfiguration(
        for item: TorrentListItem,
        source: PopoverSource
    ) -> SwipeActionsConfiguration? {
        guard let torrent = torrentMapper.map[item.hash]?.value else { return nil }

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
            .eraseError()
            .receive(on: DispatchQueue.main)
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
                self?.labelsSubject.send(update.1)
                self?.torrentMapper.update(with: update.0)
                self?.isLoadingSubject.send(false)
            }, receiveCompletion: { [weak self] _ in
                self?.isLoadingSubject.send(false)
            })
            .asVoid()
            .eraseToAnyPublisher()
    }
}
