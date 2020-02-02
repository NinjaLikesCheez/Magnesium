//
//  DelugeTorrentDetailViewModel.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-07.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import Foundation
import Preferences
import ViewModel

final class DelugeTorrentDetailViewModel: ViewModel, EventEmitter {
    private let client: DelugeClient
    private let preferences: Preferences
    private let refresher: DelugeRefreshable
    private let subject: CurrentValueSubject<DelugeTorrent, Never>
    private let isLoadingSubject = CurrentValueSubject<Bool, Never>(false)
    private let eventSubject = PassthroughSubject<TorrentDetailEvent, Never>()
    private var observers = [AnyCancellable]()
    private var autoRefreshTimer: Timer?
    private var timerIntervalObserver: AnyCancellable?
    let state: TorrentDetailViewState

    private let files: ValueMapper<String, DelugeTorrentFile> = {
        ValueMapper(filter: Just {
            $0.sorted {
                $0.value.path.compare(
                    $1.value.path,
                    options: [.numeric, .caseInsensitive]
                ) == .orderedAscending
            }
        }.eraseToAnyPublisher())
    }()

    var events: AnyPublisher<TorrentDetailEvent, Never> {
        return eventSubject.eraseToAnyPublisher()
    }

    init(
        subject: CurrentValueSubject<DelugeTorrent, Never>,
        client: DelugeClient,
        preferences: Preferences,
        refresher: DelugeRefreshable
    ) {
        self.subject = subject
        self.preferences = preferences
        self.client = client
        self.refresher = refresher

        let sections = subject
            .combineLatest(files.values)
            .map { torrent, files in
                DelugeTorrentDetailViewModel.createSections(
                    subject: subject,
                    torrent: torrent,
                    files: files
                )
            }
            .removeDuplicates()
            .ui()
            .eraseToAnyPublisher()
        state = TorrentDetailViewState(sections: sections, isLoading: isLoadingSubject.eraseToAnyPublisher())

        refreshFiles()
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &observers)
    }

    deinit {
        autoRefreshTimer?.invalidate()
    }

    private static func createSections(
        subject: CurrentValueSubject<DelugeTorrent, Never>,
        torrent: DelugeTorrent,
        files: [CurrentValueSubject<DelugeTorrentFile, Never>]
    ) -> [TorrentDetailSection] {
        var sections = [TorrentDetailSection]()
        sections.append(TorrentDetailSection(type: .header, items: [
            .header(AnyViewModel(DelugeTorrentDetailHeaderViewModel(subject: subject))),
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
                .file(AnyViewModel(DelugeTorrentDetailFileViewModel(subject: $0)))
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
        refresher.refreshTorrents()
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
        client.recheck(hashes: [subject.value.hash])
            .handleEvents(receiveCompletion: { [weak self] completion in
                guard let strongSelf = self, case .finished = completion else { return }
                strongSelf.refresher.refreshTorrents()
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
        client.pause(hashes: [subject.value.hash])
            .handleEvents(receiveCompletion: { [weak self] completion in
                guard let strongSelf = self, case .finished = completion else { return }
                strongSelf.refresher.refreshTorrents()
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
        client.resume(hashes: [subject.value.hash])
            .handleEvents(receiveCompletion: { [weak self] completion in
                guard let strongSelf = self, case .finished = completion else { return }
                strongSelf.refresher.refreshTorrents()
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
        client.remove(hashes: [subject.value.hash], removeData: removeData)
            .handleEvents(receiveCompletion: { [weak self] completion in
                guard let strongSelf = self, case .finished = completion else { return }
                strongSelf.refresher.refreshTorrents()
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
        return client.fetchTorrentFiles(hash: subject.value.hash)
            .handleEvents(receiveOutput: { [weak self] new in
                self?.files.update(with: new.map { ($0.path, $0) })
            })
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
