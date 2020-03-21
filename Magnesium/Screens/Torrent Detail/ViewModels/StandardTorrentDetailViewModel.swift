import Combine
import Foundation
import Preferences
import ViewModel

protocol StandardTorrentDetailViewModelImplementation {
    associatedtype Torrent: StandardTorrent
    associatedtype Label: StandardLabel
    associatedtype File: StandardTorrentFile
    func refresh() -> AnyPublisher<Void, Error>
    func updateFiles(_ torrent: Torrent) -> AnyPublisher<[File], Error>
    func pause(_ torrent: Torrent) -> AnyPublisher<Void, Error>
    func resume(_ torrent: Torrent) -> AnyPublisher<Void, Error>
    func remove(_ torrent: Torrent, removeData: Bool) -> AnyPublisher<Void, Error>
    func verify(_ torrent: Torrent) -> AnyPublisher<Void, Error>
    func setLabel(_ label: Label, for torrent: Torrent) -> AnyPublisher<Void, Error>
    func updateTrackers(for torrent: Torrent) -> AnyPublisher<Void, Error>
    func moveDownloadFolder(for torrent: Torrent, to path: String) -> AnyPublisher<Void, Error>
}

final class StandardTorrentDetailViewModel<Implementation: StandardTorrentDetailViewModelImplementation>: ViewModel {
    typealias Torrent = Implementation.Torrent
    typealias Label = Implementation.Label
    typealias File = Implementation.File

    private let implementation: Implementation
    private let torrent: CurrentValueSubject<Torrent, Never>
    private let labels: CurrentValueSubject<[Label], Never>
    private let isRefreshingSubject = CurrentValueSubject<Bool, Never>(false)
    private let eventSubject = PassthroughSubject<TorrentDetailEvent, Never>()
    private var cancellables = Set<AnyCancellable>()
    private var autoRefreshTimer: Timer?
    private var timerIntervalObserver: AnyCancellable?
    let state: TorrentDetailViewState

    let files: ValueMapper<Int, File> = {
        ValueMapper(filter: Just {
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
    }()

    var events: AnyPublisher<TorrentDetailEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    init(
        implementation: Implementation,
        torrent: CurrentValueSubject<Torrent, Never>,
        labels: CurrentValueSubject<[Label], Never>
    ) {
        self.implementation = implementation
        self.torrent = torrent
        self.labels = labels

        let sections = torrent
            .combineLatest(files.values)
            .map { torrentValue, files in
                Self.createSections(
                    subject: torrent,
                    torrent: torrentValue,
                    files: files
                )
            }
            .removeDuplicates()
            .ui()
            .eraseToAnyPublisher()
        state = TorrentDetailViewState(
            hash: torrent.value.hash,
            sections: sections,
            isRefreshing: isRefreshingSubject.eraseToAnyPublisher()
        )

        refreshFiles()
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)
    }

    private static func createSections(
        subject: CurrentValueSubject<Torrent, Never>,
        torrent: Torrent,
        files: [CurrentValueSubject<File, Never>]
    ) -> [TorrentDetailSection] {
        var sections = [TorrentDetailSection]()
        sections.append(TorrentDetailSection(type: .header, items: [
            .header(TorrentDetailHeaderItem(torrent: subject)),
        ]))
        sections.append(TorrentDetailSection(type: .info, items: [
            .info(TorrentDetailInfoItem(
                name: L10n.torrentInfoSize,
                value: subject.map { Formatters.bytes.string(fromByteCount: $0.size) }.ui().eraseToAnyPublisher()
            )),
            .info(TorrentDetailInfoItem(
                name: L10n.torrentInfoDownloadSpeed,
                value: subject
                    .map { "\(Formatters.bytes.string(fromByteCount: $0.downloadRate))/s" }
                    .ui()
                    .eraseToAnyPublisher()
            )),
            .info(TorrentDetailInfoItem(
                name: L10n.torrentInfoUploadSpeed,
                value: subject
                    .map { "\(Formatters.bytes.string(fromByteCount: $0.uploadRate))/s" }
                    .ui()
                    .eraseToAnyPublisher()
            )),
            .info(TorrentDetailInfoItem(
                name: L10n.torrentInfoDownloaded,
                value: subject.map { Formatters.bytes.string(fromByteCount: $0.downloaded) }.ui().eraseToAnyPublisher()
            )),
            .info(TorrentDetailInfoItem(
                name: L10n.torrentInfoUploaded,
                value: subject.map { Formatters.bytes.string(fromByteCount: $0.uploaded) }.ui().eraseToAnyPublisher()
            )),
            .info(TorrentDetailInfoItem(
                name: L10n.torrentInfoETA,
                value: subject.map(\.formattedETA).ui().eraseToAnyPublisher()
            )),
            .info(TorrentDetailInfoItem(
                name: L10n.torrentInfoRatio,
                value: subject.map { $0.formattedRatio(precision: 3) }.ui().eraseToAnyPublisher()
            )),
            .info(TorrentDetailInfoItem(
                name: L10n.torrentInfoPeers,
                value: subject
                    .map { L10n.torrentPeers(peers: $0.peers, totalPeers: $0.totalPeers) }
                    .ui()
                    .eraseToAnyPublisher()
            )),
            .info(TorrentDetailInfoItem(
                name: L10n.torrentInfoSeed,
                value: subject.map { L10n.torrentPeers(peers: $0.seeds, totalPeers: $0.totalSeeds) }
                    .ui()
                    .eraseToAnyPublisher()
            )),
            .info(TorrentDetailInfoItem(
                name: L10n.torrentInfoDownloadFolder,
                value: subject.map { ($0.downloadPath as NSString).lastPathComponent }
                    .ui()
                    .eraseToAnyPublisher(),
                expandedValue: subject.map(\.downloadPath).ui().eraseToAnyPublisher()
            )),
        ]))

        if !torrent.trackerStrings.isEmpty {
            sections.append(TorrentDetailSection(type: .trackers, items: torrent.trackerStrings.map { .tracker($0) }))
        }

        if !files.isEmpty {
            sections.append(TorrentDetailSection(type: .files, items: files.map {
                .file(TorrentDetailFileItem(file: $0))
            }))
        }

        return sections
    }

    deinit {
        autoRefreshTimer?.invalidate()
    }

    func handle(_ event: TorrentDetailViewEvent) {
        switch event {
        case .appear:
            handleAppear()
        case .disappear:
            handleDisappear()
        case .refresh:
            handleRefresh()
        case let .moreOptions(source):
            handleMoreOptions(from: source)
        case .pause:
            pause()
        case .resume:
            resume()
        case let .remove(source):
            presentRemoveOptions(from: source)
        }
    }

    private func handleAppear() {
        if let timer = autoRefreshTimer, timer.isValid {
            return
        }

        timerIntervalObserver = Current.preferences.valuePublisher(for: .autoRefreshInterval)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] value in
                self?.configureAutoRefreshTimer(interval: value)
            })
    }

    private func handleDisappear() {
        autoRefreshTimer?.invalidate()
        timerIntervalObserver?.cancel()
    }

    private func handleRefresh() {
        isRefreshingSubject.send(true)
        implementation.refresh()
            .mapError { $0 as Error }
            .flatMap { [weak self] _ -> AnyPublisher<Void, Error> in
                guard let strongSelf = self else { return Empty(completeImmediately: true).eraseToAnyPublisher() }
                return strongSelf.refreshFiles()
            }
            .ui()
            .handleEvents(receiveCompletion: { [weak self] completion in
                self?.isRefreshingSubject.send(false)
                guard case let .failure(error) = completion else { return }
                self?.showError(title: L10n.refreshError, message: error.localizedDescription)
            })
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)
    }

    private func handleMoreOptions(from source: PopoverSource) {
        let torrent = self.torrent.value
        var activities = [Activity]()

        if !labels.value.isEmpty {
            activities.append(.setLabel {
                self.presentLabelSelection(from: source)
            })
        }

        activities.append(.verifyFiles {
            self.verify()
        })

        activities.append(.moveDownloadFolder {
            let subject = PassthroughSubject<String, Never>()
            subject
                .sink { [weak self] path in
                    self?.moveDownloadFolder(to: path)
                }
                .store(in: &self.cancellables)
            self.eventSubject.send(.moveDownloadFolder(currentPath: torrent.downloadPath, subject: subject))
        })

        activities.append(.updateTrackers {
            self.updateTrackers()
        })

        eventSubject.send(.activities(activities, torrent: torrent, source: source))
    }

    private func pause() {
        implementation.pause(torrent.value)
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

    private func resume() {
        implementation.resume(torrent.value)
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

    private func remove(removeData: Bool) {
        implementation.remove(torrent.value, removeData: removeData)
            .handleEvents(receiveCompletion: { [weak self] completion in
                guard let strongSelf = self, case .finished = completion else { return }
                strongSelf.implementation.refresh()
                    .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
                    .store(in: &strongSelf.cancellables)
            })
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
        implementation.verify(torrent.value)
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

    private func setLabel(_ label: Label) {
        implementation.setLabel(label, for: torrent.value)
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

    private func updateTrackers() {
        implementation.updateTrackers(for: torrent.value)
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

    private func moveDownloadFolder(to path: String) {
        implementation.moveDownloadFolder(for: torrent.value, to: path)
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

    private func presentRemoveOptions(from source: PopoverSource) {
        var alert = Alert(title: nil, message: nil, style: .actionSheet(source))
        alert.addAction(AlertAction(title: L10n.removeTorrentOptionKeepData, style: .default) {
            self.remove(removeData: false)
        })
        alert.addAction(AlertAction(title: L10n.removeTorrentOptionRemoveData, style: .destructive) {
            self.remove(removeData: true)
        })
        alert.addAction(.cancel)
        eventSubject.send(.alert(alert))
    }

    private func presentLabelSelection(from source: PopoverSource) {
        var alert = Alert(title: nil, message: nil, style: .actionSheet(source))
        for label in labels.value {
            alert.addAction(AlertAction(title: label.displayName, style: .default) {
                self.setLabel(label)
            })
        }
        alert.addAction(.cancel)
        eventSubject.send(.alert(alert))
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
        refreshFiles()
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)
    }

    private func refreshFiles() -> AnyPublisher<Void, Error> {
        implementation.updateFiles(torrent.value)
            .handleEvents(receiveOutput: { [weak self] new in
                self?.files.update(with: new.map { ($0.index, $0) })
            })
            .map { _ in () }
            .eraseToAnyPublisher()
    }
}
