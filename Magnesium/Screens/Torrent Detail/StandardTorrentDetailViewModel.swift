import Combine
import CommonModels
import Foundation
import Preferences
import UIKit
import ViewModel

final class StandardTorrentDetailViewModel: ViewModel {
    private let implementation: StandardTorrentDetailImplementation
    private let torrentSubject: CurrentValueSubject<StandardTorrent, Never>
    private let labelsSubject: CurrentValueSubject<[StandardLabel], Never>
    private let sectionsSubject = CurrentValueSubject<[TorrentDetailSection], Never>([])
    private let fileMapper: ValueMapper<Int, StandardTorrentFile>
    private let isRefreshingSubject = CurrentValueSubject<Bool, Never>(false)
    private let editSectionSubject = CurrentValueSubject<TorrentDetailSectionType?, Never>(nil)
    private let multiSelectCountSubject = CurrentValueSubject<Int, Never>(0)
    private let eventSubject = PassthroughSubject<TorrentDetailViewModelEvent, Never>()
    private var cancellables = Set<AnyCancellable>()
    private var autoRefreshTimer: Timer?
    private var timerIntervalObserver: AnyCancellable?
    private var _values: TorrentDetailViewValues!

    var values: TorrentDetailViewValues {
        _values
    }

    var eventPublisher: AnyPublisher<TorrentDetailViewModelEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    init(
        implementation: StandardTorrentDetailImplementation,
        torrentSubject: CurrentValueSubject<StandardTorrent, Never>,
        labelsSubject: CurrentValueSubject<[StandardLabel], Never>
    ) {
        self.implementation = implementation
        self.torrentSubject = torrentSubject
        self.labelsSubject = labelsSubject

        fileMapper = ValueMapper(filter: Just {
            $0.sorted {
                let result = $0.value.name.compare(
                    $1.value.name,
                    options: [.numeric, .caseInsensitive]
                )
                switch result {
                case .orderedSame:
                    return $0.value.index < $1.value.index
                case .orderedAscending:
                    return true
                case .orderedDescending:
                    return false
                }
            }
        }.eraseToAnyPublisher())

        let sections = fileMapper.valuesPublisher
            .map { files in
                Self.createSections(
                    torrentSubject: torrentSubject,
                    files: files
                )
            }
            .handleEvents(receiveOutput: { [weak self] in
                self?.sectionsSubject.send($0)
            })
            .removeDuplicates()
            .ui()
            .eraseToAnyPublisher()

        let toolbarInfo = editSectionSubject
            .combineLatest(multiSelectCountSubject)
            .map { editSection, count -> String in
                switch editSection {
                case .files:
                    return L10n.selectedCount(count)
                default:
                    return ""
                }
            }
            .ui()
            .eraseToAnyPublisher()

        _values = .init(
            hash: torrentSubject.value.hash,
            sections: sections,
            isRefreshing: isRefreshingSubject.ui().eraseToAnyPublisher(),
            toolbarInfo: toolbarInfo,
            editSection: editSectionSubject.ui().eraseToAnyPublisher(),
            contextMenu: { [weak self] in
                self?.contextMenuForItem(at: $0)
            }
        )

        refreshFiles()
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)
    }

    private static func createSections(
        torrentSubject: CurrentValueSubject<StandardTorrent, Never>,
        files: [CurrentValueSubject<StandardTorrentFile, Never>]
    ) -> [TorrentDetailSection] {
        let torrent = torrentSubject.value

        var sections = [TorrentDetailSection]()
        sections.append(.init(type: .header, items: [
            .header(.init(torrentSubject: torrentSubject)),
        ]))
        sections.append(.init(type: .info, items: [
            .info(.init(
                name: L10n.torrentInfoSize,
                value: torrentSubject.map { Formatters.bytes.string(fromByteCount: $0.size) }.ui().eraseToAnyPublisher()
            )),
            .info(.init(
                name: L10n.torrentInfoDownloadSpeed,
                value: torrentSubject
                    .map { "\(Formatters.bytes.string(fromByteCount: $0.downloadRate))/s" }
                    .ui()
                    .eraseToAnyPublisher()
            )),
            .info(.init(
                name: L10n.torrentInfoUploadSpeed,
                value: torrentSubject
                    .map { "\(Formatters.bytes.string(fromByteCount: $0.uploadRate))/s" }
                    .ui()
                    .eraseToAnyPublisher()
            )),
            .info(.init(
                name: L10n.torrentInfoDownloaded,
                value: torrentSubject
                    .map { Formatters.bytes.string(fromByteCount: $0.downloaded) }
                    .ui()
                    .eraseToAnyPublisher()
            )),
            .info(.init(
                name: L10n.torrentInfoUploaded,
                value: torrentSubject
                    .map { Formatters.bytes.string(fromByteCount: $0.uploaded) }
                    .ui()
                    .eraseToAnyPublisher()
            )),
            .info(.init(
                name: L10n.torrentInfoETA,
                value: torrentSubject.map(\.formattedETA).ui().eraseToAnyPublisher()
            )),
            .info(.init(
                name: L10n.torrentInfoRatio,
                value: torrentSubject.map { $0.formattedRatio(precision: 3) }.ui().eraseToAnyPublisher()
            )),
            .info(.init(
                name: L10n.torrentInfoPeers,
                value: torrentSubject
                    .map { L10n.torrentPeers(peers: $0.peers, totalPeers: $0.totalPeers) }
                    .ui()
                    .eraseToAnyPublisher()
            )),
            .info(.init(
                name: L10n.torrentInfoSeed,
                value: torrentSubject
                    .map { L10n.torrentPeers(peers: $0.seeds, totalPeers: $0.totalSeeds) }
                    .ui()
                    .eraseToAnyPublisher()
            )),
            .info(.init(
                name: L10n.torrentInfoDownloadFolder,
                value: torrentSubject.map { ($0.downloadPath as NSString).lastPathComponent }
                    .ui()
                    .eraseToAnyPublisher(),
                expandedValue: torrentSubject.map(\.downloadPath).ui().eraseToAnyPublisher()
            )),
        ]))

        if !torrent.trackers.isEmpty {
            sections.append(.init(type: .trackers, items: torrent.trackers.map { .tracker($0) }))
        }

        if !files.isEmpty {
            sections.append(.init(type: .files, items: files.map {
                .file(.init(fileSubject: $0))
            }))
        }

        return sections
    }

    deinit {
        autoRefreshTimer?.invalidate()
    }

    // MARK: View Events

    // swiftlint:disable:next cyclomatic_complexity
    func send(_ event: TorrentDetailViewEvent) {
        switch event {
        case .appeared:
            handleAppeared()
        case .disappeared:
            handleDisappeared()
        case .refresh:
            handleRefresh()
        case let .moreOptionsSelected(source):
            presentActivities(from: source)
        case .pauseSelected:
            pause()
        case .resumeSelected:
            resume()
        case let .removeSelected(source):
            presentRemoveOptions(from: source)
        case let .editSectionSelected(section):
            editSectionSubject.send(section)
        case .doneEditingSelected:
            editSectionSubject.send(nil)
        case let .multiSelectUpdated(indices):
            multiSelectCountSubject.send(indices.count)
        case let .setFilePrioritySelected(indexPaths, source):
            presentFilePrioritySelection(for: indexPaths, from: source)
        }
    }

    private func handleAppeared() {
        if let timer = autoRefreshTimer, timer.isValid {
            return
        }

        timerIntervalObserver = Current.preferences.valuePublisher(for: .autoRefreshInterval)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] value in
                self?.configureAutoRefreshTimer(interval: value)
            })
    }

    private func handleDisappeared() {
        autoRefreshTimer?.invalidate()
        timerIntervalObserver?.cancel()
    }

    private func handleRefresh() {
        isRefreshingSubject.send(true)
        implementation.refresh()
            .eraseError()
            .append(refreshFiles())
            .ui()
            .handleEvents(receiveCompletion: { [weak self] completion in
                self?.isRefreshingSubject.send(false)
                guard case let .failure(error) = completion else { return }
                self?.showError(title: L10n.refreshError, message: error.localizedDescription)
            })
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)
    }

    private func presentActivities(from source: PopoverSource) {
        let torrent = torrentSubject.value
        var activities = [Activity]()

        if !labelsSubject.value.isEmpty {
            activities.append(.setLabel {
                self.presentLabelSelection(from: source)
            })
        }

        activities.append(.verifyFiles {
            self.verify()
        })

        activities.append(.moveDownloadFolder {
            let subject = PassthroughSubject<String, Never>()
            subject.sink { [weak self] path in
                self?.moveDownloadFolder(to: path)
            }.store(in: &self.cancellables)
            self.eventSubject.send(.moveDownloadFolder(currentPath: torrent.downloadPath, subject: subject))
        })

        activities.append(.updateTrackers {
            self.updateTrackers()
        })

        eventSubject.send(.activities(activities, torrent: torrent, source: source))
    }

    private func pause() {
        implementation.pause(torrentSubject.value)
            .append(implementation.refresh().replaceError(with: ()).setFailureType(to: Error.self))
            .ui()
            .sink(receiveCompletion: { [weak self] completion in
                guard case let .failure(error) = completion else { return }
                self?.showError(title: L10n.pauseError, message: error.localizedDescription)
            }, receiveValue: { _ in })
            .store(in: &cancellables)
    }

    private func resume() {
        implementation.resume(torrentSubject.value)
            .append(implementation.refresh().replaceError(with: ()).setFailureType(to: Error.self))
            .ui()
            .sink(receiveCompletion: { [weak self] completion in
                guard case let .failure(error) = completion else { return }
                self?.showError(title: L10n.resumeError, message: error.localizedDescription)
            }, receiveValue: { _ in })
            .store(in: &cancellables)
    }

    private func remove(removeData: Bool) {
        implementation.remove(torrentSubject.value, removeData)
            .append(implementation.refresh().replaceError(with: ()).setFailureType(to: Error.self))
            .ui()
            .sink(receiveCompletion: { [weak self] completion in
                switch completion {
                case .finished:
                    self?.eventSubject.send(.complete)
                case let .failure(error):
                    self?.showError(title: L10n.removeError, message: error.localizedDescription)
                }
            }, receiveValue: { _ in })
            .store(in: &cancellables)
    }

    private func verify() {
        implementation.verify(torrentSubject.value)
            .append(implementation.refresh().replaceError(with: ()).setFailureType(to: Error.self))
            .ui()
            .sink(receiveCompletion: { [weak self] completion in
                guard case let .failure(error) = completion else { return }
                self?.showError(title: L10n.verifyFilesError, message: error.localizedDescription)
                }, receiveValue: { _ in })
            .store(in: &cancellables)
    }

    private func setLabel(_ label: StandardLabel) {
        implementation.setLabel(label, torrentSubject.value)
            .append(implementation.refresh().replaceError(with: ()).setFailureType(to: Error.self))
            .ui()
            .sink(receiveCompletion: { [weak self] completion in
                guard case let .failure(error) = completion else { return }
                self?.showError(title: L10n.setLabelError, message: error.localizedDescription)
            }, receiveValue: { _ in })
            .store(in: &cancellables)
    }

    private func updateTrackers() {
        implementation.updateTrackers(torrentSubject.value)
            .append(implementation.refresh().replaceError(with: ()).setFailureType(to: Error.self))
            .ui()
            .sink(receiveCompletion: { [weak self] completion in
                guard case let .failure(error) = completion else { return }
                self?.showError(title: L10n.updateTrackersError, message: error.localizedDescription)
            }, receiveValue: { _ in })
            .store(in: &cancellables)
    }

    private func moveDownloadFolder(to path: String) {
        implementation.moveDownloadFolder(path, torrentSubject.value)
            .append(implementation.refresh().replaceError(with: ()).setFailureType(to: Error.self))
            .ui()
            .sink(receiveCompletion: { [weak self] completion in
                guard case let .failure(error) = completion else { return }
                self?.showError(title: L10n.moveDownloadFolderError, message: error.localizedDescription)
            }, receiveValue: { _ in })
            .store(in: &cancellables)
    }

    private func presentRemoveOptions(from source: PopoverSource) {
        eventSubject.send(.alert(.init(style: .actionSheet(source), actions: [
            .init(title: L10n.removeTorrentOptionKeepData, style: .default) {
                self.remove(removeData: false)
            },
            .init(title: L10n.removeTorrentOptionRemoveData, style: .destructive) {
                self.remove(removeData: true)
            },
            .cancel,
        ])))
    }

    private func presentLabelSelection(from source: PopoverSource) {
        let labelActions = labelsSubject.value.map { label in
            AlertAction(title: label.displayName, style: .default) {
                self.setLabel(label)
            }
        }
        eventSubject.send(.alert(.init(style: .actionSheet(source), actions: labelActions + [.cancel])))
    }

    private func presentFilePrioritySelection(for indexPaths: [IndexPath], from source: PopoverSource) {
        let files = indexPaths.reduce(into: [StandardTorrentFile]()) {
            switch sectionsSubject.value[$1.section].items[$1.row] {
            case let .file(item):
                guard let file = self.fileMapper.map[item.id] else {
                    return
                }

                $0.append(file.value)
            default:
                break
            }
        }

        eventSubject.send(.alert(.init(
            title: L10n.setPriority,
            message: L10n.fileCount(files.count),
            style: .actionSheet(source),
            actions: [
                .init(title: L10n.disabledPriority, style: .default) { [weak self] in
                    self?.setPriority(.disabled, for: files)
                },
                .init(title: L10n.lowPriority, style: .default) { [weak self] in
                    self?.setPriority(.low, for: files)
                },
                .init(title: L10n.normalPriority, style: .default) { [weak self] in
                    self?.setPriority(.normal, for: files)
                },
                .init(title: L10n.highPriority, style: .default) { [weak self] in
                    self?.setPriority(.high, for: files)
                },
                .cancel,
            ]
        )))
    }

    private func showError(title: String, message: String?) {
        eventSubject.send(.alert(.init(title: title, message: message, style: .alert, action: .ok)))
    }

    // MARK: View Functions

    private func contextMenuForItem(at indexPath: IndexPath) -> Menu? {
        switch sectionsSubject.value[indexPath.section].items[indexPath.row] {
        case let .file(item):
            guard let file = fileMapper.map[item.id] else {
                return nil
            }

            return Menu(children: [
                .action(.init(
                    title: L10n.disabledPriority,
                    state: file.value.priority == .disabled ? .on : .off,
                    handler: { [weak self] in
                        self?.setPriority(.disabled, for: [file.value])
                    }
                )),
                .action(.init(
                    title: L10n.lowPriority,
                    state: file.value.priority == .low ? .on : .off,
                    handler: { [weak self] in
                        self?.setPriority(.low, for: [file.value])
                    }
                )),
                .action(.init(
                    title: L10n.normalPriority,
                    state: file.value.priority == .normal ? .on : .off,
                    handler: { [weak self] in
                        self?.setPriority(.normal, for: [file.value])
                    }
                )),
                .action(.init(
                    title: L10n.highPriority,
                    state: file.value.priority == .high ? .on : .off,
                    handler: { [weak self] in
                        self?.setPriority(.high, for: [file.value])
                    }
                )),
            ])
        default:
            return nil
        }
    }

    private func setPriority(_ priority: TorrentPriority, for files: [StandardTorrentFile]) {
        let priorityMap = files.reduce(into: [StandardTorrentFile: TorrentPriority]()) { $0[$1] = priority }
        implementation.setPriority(torrentSubject.value, fileMapper.map.values.map(\.value), priorityMap)
            .append(
                implementation.refreshFiles(torrentSubject.value)
                    .asVoid()
                    .replaceError(with: ())
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            )
            .ui()
            .sink(receiveCompletion: { [weak self] completion in
                guard case let .failure(error) = completion else { return }
                self?.showError(title: L10n.setPriorityError, message: error.localizedDescription)
            }, receiveValue: { _ in })
            .store(in: &cancellables)
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
        refreshFiles()
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)
    }

    private func refreshFiles() -> AnyPublisher<Void, Error> {
        implementation.refreshFiles(torrentSubject.value)
            .handleEvents(receiveOutput: { [weak self] new in
                self?.fileMapper.update(with: new.map { ($0.index, $0) })
            })
            .asVoid()
            .eraseToAnyPublisher()
    }
}
