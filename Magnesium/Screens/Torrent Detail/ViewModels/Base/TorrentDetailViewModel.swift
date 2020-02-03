//
//  TorrentDetailViewModel.swift
//  Magnesium
//
//  Created by James Hurst on 2019-11-16.
//  Copyright © 2019 James Hurst. All rights reserved.
//

import Combine
import Foundation
import Preferences
import ViewModel

typealias AnyTorrentDetailViewModel = AnyEmitterViewModel<
    TorrentDetailEvent,
    TorrentDetailViewEvent,
    TorrentDetailViewState
>

enum TorrentDetailEvent {
    case complete
    case alert(Alert, source: PopoverSource?)
}

enum TorrentDetailViewEvent {
    case appear
    case disappear
    case refresh
    case moreOptions(source: PopoverSource)
    case pause
    case resume
    case remove(source: PopoverSource)
}

struct TorrentDetailViewState {
    var sections: AnyPublisher<[TorrentDetailSection], Never>
    var isLoading: AnyPublisher<Bool, Never>
}

protocol StandardDetailTorrent: StandardTorrent {
    var trackers: [String] { get }
}

protocol StandardDetailTorrentFile {
    var index: Int { get }
    var name: String { get }
    var size: Int64 { get }
    var progress: Float { get }
}

protocol StandardTorrentDetailViewModelImplementation {
    func refresh() -> AnyPublisher<Void, Error>
    func pause() -> AnyPublisher<Void, Error>
    func resume() -> AnyPublisher<Void, Error>
    func remove(removeData: Bool) -> AnyPublisher<Void, Error>
    func recheck() -> AnyPublisher<Void, Error>
    func updateFiles() -> AnyPublisher<Void, Error>
}

class StandardTorrentDetailViewModel<
    Torrent: StandardDetailTorrent,
    File: StandardDetailTorrentFile
>: ViewModel, EventEmitter {
    private var implementation: StandardTorrentDetailViewModelImplementation!
    private let preferences: Preferences
    private let subject: CurrentValueSubject<Torrent, Never>
    private let isLoadingSubject = CurrentValueSubject<Bool, Never>(false)
    private let eventSubject = PassthroughSubject<TorrentDetailEvent, Never>()
    private var observers = [AnyCancellable]()
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
        return eventSubject.eraseToAnyPublisher()
    }

    init(subject: CurrentValueSubject<Torrent, Never>, preferences: Preferences) {
        self.subject = subject
        self.preferences = preferences

        let sections = subject
            .combineLatest(files.values)
            .map { torrent, files in
                Self.createSections(
                    subject: subject,
                    torrent: torrent,
                    files: files
                )
            }
            .removeDuplicates()
            .ui()
            .eraseToAnyPublisher()
        state = TorrentDetailViewState(sections: sections, isLoading: isLoadingSubject.eraseToAnyPublisher())
    }

    func setup(with implementation: StandardTorrentDetailViewModelImplementation) {
        self.implementation = implementation
        refreshFiles()
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &observers)
    }

    deinit {
        autoRefreshTimer?.invalidate()
    }

    private static func createSections(
        subject: CurrentValueSubject<Torrent, Never>,
        torrent: Torrent,
        files: [CurrentValueSubject<File, Never>]
    ) -> [TorrentDetailSection] {
        var sections = [TorrentDetailSection]()
        sections.append(TorrentDetailSection(type: .header, items: [
            .header(AnyViewModel(StandardTorrentDetailHeaderViewModel(subject: subject))),
        ]))
        let ui = subject.ui()
        sections.append(TorrentDetailSection(type: .info, items: [
            .info("Size", ui.map { ByteFormatter.string(fromByteCount: $0.size) }.eraseToAnyPublisher()),
            .info("Download Speed", ui
                .map { "\(ByteFormatter.string(fromByteCount: $0.downloadRate))/s" }
                .eraseToAnyPublisher()),
            .info("Upload Speed", ui
                .map { "\(ByteFormatter.string(fromByteCount: $0.uploadRate))/s" }
                .eraseToAnyPublisher()),
            .info("Downloaded", ui.map { ByteFormatter.string(fromByteCount: $0.downloaded) }.eraseToAnyPublisher()),
            .info("Uploaded", ui.map { ByteFormatter.string(fromByteCount: $0.uploaded) }.eraseToAnyPublisher()),
            .info("ETA", ui.map(\.etaString).eraseToAnyPublisher()),
            .info("Ratio", ui.map { $0.ratioString(precision: 3) }.eraseToAnyPublisher()),
            .info("Peers", ui.map { "\($0.peers) (\($0.totalPeers))" }.eraseToAnyPublisher()),
            .info("Seeds", ui.map { "\($0.seeds) (\($0.totalSeeds))" }.eraseToAnyPublisher()),
        ]))

        if !torrent.trackers.isEmpty {
            sections.append(TorrentDetailSection(type: .trackers, items: torrent.trackers.map { .tracker($0) }))
        }

        if !files.isEmpty {
            sections.append(TorrentDetailSection(type: .files, items: files.map {
                .file(AnyViewModel(StandardTorrentDetailFileViewModel(subject: $0)))
            }))
        }

        return sections
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
            handleMoreOptions(source: source)
        case .pause:
            handlePause()
        case .resume:
            handleResume()
        case let .remove(source):
            handleRemove(source: source)
        }
    }

    private func handleAppear() {
        if let timer = autoRefreshTimer, timer.isValid {
            return
        }

        timerIntervalObserver = preferences.valuePublisher(for: PreferenceKeys.autoRefreshInterval)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] value in
                self?.configureAutoRefreshTimer(interval: value)
            })
    }

    private func handleDisappear() {
        autoRefreshTimer?.invalidate()
        timerIntervalObserver?.cancel()
    }

    private func handleRefresh() {
        guard !isLoadingSubject.value else { return }
        isLoadingSubject.send(true)
        implementation.refresh()
            .mapError { $0 as Error }
            .flatMap { [weak self] _ -> AnyPublisher<Void, Error> in
                guard let strongSelf = self else { return Empty(completeImmediately: true).eraseToAnyPublisher() }
                return strongSelf.refreshFiles()
            }
            .ui()
            .handleEvents(receiveCompletion: { [weak self] completion in
                self?.isLoadingSubject.send(false)
                guard case let .failure(error) = completion else { return }
                self?.showError(title: "Update Failed", message: error.localizedDescription)
            })
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &observers)
    }

    private func handleMoreOptions(source: PopoverSource) {
        var alert = Alert(title: nil, message: nil, style: .actionSheet)
        alert.addAction(AlertAction(title: "Force Recheck", style: .default) {
            self.recheck()
        })
        alert.addAction(AlertAction(title: "Cancel", style: .cancel))
        eventSubject.send(.alert(alert, source: source))
    }

    private func recheck() {
        implementation.recheck()
            .handleEvents(receiveCompletion: { [weak self] completion in
                guard let strongSelf = self, case .finished = completion else { return }
                strongSelf.implementation.refresh()
                    .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
                    .store(in: &strongSelf.observers)
            })
            .ui()
            .sink(receiveCompletion: { [weak self] completion in
                guard case let .failure(error) = completion else { return }
                self?.showError(title: "Failed to Recheck", message: error.localizedDescription)
                }, receiveValue: { _ in })
            .store(in: &observers)
    }

    private func handlePause() {
        implementation.pause()
            .handleEvents(receiveCompletion: { [weak self] completion in
                guard let strongSelf = self, case .finished = completion else { return }
                strongSelf.implementation.refresh()
                    .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
                    .store(in: &strongSelf.observers)
            })
            .ui()
            .sink(receiveCompletion: { [weak self] completion in
                guard case let .failure(error) = completion else { return }
                self?.showError(title: "Failed to Pause", message: error.localizedDescription)
                }, receiveValue: { _ in })
            .store(in: &observers)
    }

    private func handleResume() {
        implementation.resume()
            .handleEvents(receiveCompletion: { [weak self] completion in
                guard let strongSelf = self, case .finished = completion else { return }
                strongSelf.implementation.refresh()
                    .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
                    .store(in: &strongSelf.observers)
            })
            .ui()
            .sink(receiveCompletion: { [weak self] completion in
                guard case let .failure(error) = completion else { return }
                self?.showError(title: "Failed to Resume", message: error.localizedDescription)
                }, receiveValue: { _ in })
            .store(in: &observers)
    }

    private func handleRemove(source: PopoverSource) {
        var alert = Alert(title: nil, message: nil, style: .actionSheet)
        alert.addAction(AlertAction(title: "Keep Data", style: .default) {
            self.remove(removeData: false)
        })
        alert.addAction(AlertAction(title: "Remove Data", style: .destructive) {
            self.remove(removeData: true)
        })
        alert.addAction(AlertAction(title: "Cancel", style: .cancel))
        eventSubject.send(.alert(alert, source: source))
    }

    private func remove(removeData: Bool) {
        implementation.remove(removeData: removeData)
            .handleEvents(receiveCompletion: { [weak self] completion in
                guard let strongSelf = self, case .finished = completion else { return }
                strongSelf.implementation.refresh()
                    .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
                    .store(in: &strongSelf.observers)
            })
            .ui()
            .sink(receiveCompletion: { [weak self] completion in
                switch completion {
                case .finished:
                    self?.eventSubject.send(.complete)
                case let .failure(error):
                    self?.showError(title: "Failed to Remove", message: error.localizedDescription)
                }
                }, receiveValue: { _ in })
            .store(in: &observers)
    }

    private func configureAutoRefreshTimer(interval: TimeInterval?) {
        autoRefreshTimer?.invalidate()
        guard let interval = interval, interval > 0 else { return }
        let timer = Timer(fire: Date().advanced(by: interval), interval: interval, repeats: true) { [weak self] in
            self?.refreshTimerFired($0)
        }
        RunLoop.main.add(timer, forMode: .common)
        autoRefreshTimer = timer
    }

    private func refreshTimerFired(_ timer: Timer) {
        refreshFiles()
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &observers)
    }

    private func refreshFiles() -> AnyPublisher<Void, Error> {
        return implementation.updateFiles()
            .mapError { $0 as Error }
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    private func showError(title: String, message: String?) {
        var alert = Alert(
            title: title,
            message: message,
            style: .alert
        )
        alert.addAction(AlertAction(title: "OK", style: .default))
        eventSubject.send(.alert(alert, source: nil))
    }
}
