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

final class DelugeTorrentDetailViewModel: TorrentDetailViewModel {
    private let client: DelugeClient
    private let preferences: Preferences
    private let refresher: DelugeRefreshable
    private let torrentSubject: CurrentValueSubject<DelugeTorrent, Never>
    private let eventSubject = PassthroughSubject<TorrentDetailEvent, Never>()
    private var observers = [AnyCancellable]()
    private var autoUpdateTimer: Timer?
    private var timerIntervalObserver: AnyCancellable?
    let sections: AnyPublisher<[TorrentDetailSection], Never>

    private let files: CurrentValueSubjectMapManager<String, DelugeTorrentFile> = {
        CurrentValueSubjectMapManager(sort: Just {
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
        torrentSubject: CurrentValueSubject<DelugeTorrent, Never>,
        client: DelugeClient,
        preferences: Preferences,
        refresher: DelugeRefreshable
    ) {
        self.torrentSubject = torrentSubject
        self.preferences = preferences
        self.client = client
        self.refresher = refresher

        sections = torrentSubject
            .combineLatest(files.sorted)
            .map { torrent, files in
                DelugeTorrentDetailViewModel.createSections(
                    torrentSubject: torrentSubject,
                    torrent: torrent,
                    files: files
                )
            }
            .removeDuplicates()
            .ui()
            .eraseToAnyPublisher()

        refreshFiles()
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &observers)
    }

    deinit {
        autoUpdateTimer?.invalidate()
    }

    private static func createSections(
        torrentSubject: CurrentValueSubject<DelugeTorrent, Never>,
        torrent: DelugeTorrent,
        files: [CurrentValueSubject<DelugeTorrentFile, Never>]
    ) -> [TorrentDetailSection] {
        var sections = [TorrentDetailSection]()
        sections.append(TorrentDetailSection(type: .header, items: [
            .header(DelugeTorrentDetailHeaderViewModel(torrentSubject: torrentSubject).eraseToAny()),
        ]))
        sections.append(TorrentDetailSection(type: .info, items: [
            .info(TorrentDetailInfoViewModel(
                name: "Size",
                value: torrentSubject
                    .map { ByteFormatter.string(fromByteCount: $0.size) }
                    .ui()
                    .eraseToAnyPublisher()
            )),
            .info(TorrentDetailInfoViewModel(
                name: "Download Speed",
                value: torrentSubject
                    .map { "\(ByteFormatter.string(fromByteCount: $0.downloadRate))/s" }
                    .ui()
                    .eraseToAnyPublisher()
            )),
            .info(TorrentDetailInfoViewModel(
                name: "Upload Speed",
                value: torrentSubject
                    .map { "\(ByteFormatter.string(fromByteCount: $0.uploadRate))/s" }
                    .ui()
                    .eraseToAnyPublisher()
            )),
            .info(TorrentDetailInfoViewModel(
                name: "Downloaded",
                value: torrentSubject
                    .map { ByteFormatter.string(fromByteCount: $0.downloaded) }
                    .ui()
                    .eraseToAnyPublisher()
            )),
            .info(TorrentDetailInfoViewModel(
                name: "Uploaded",
                value: torrentSubject
                    .map { ByteFormatter.string(fromByteCount: $0.uploaded) }
                    .ui()
                    .eraseToAnyPublisher()
            )),
            .info(TorrentDetailInfoViewModel(
                name: "ETA",
                value: torrentSubject
                    .map(\.etaString)
                    .ui()
                    .eraseToAnyPublisher()
            )),
            .info(TorrentDetailInfoViewModel(
                name: "Ratio",
                value: torrentSubject
                    .map { $0.ratioString(precision: 3) }
                    .ui()
                    .eraseToAnyPublisher()
            )),
            .info(TorrentDetailInfoViewModel(
                name: "Peers",
                value: torrentSubject
                    .map { "\($0.peers) (\($0.totalPeers))" }
                    .ui()
                    .eraseToAnyPublisher()
            )),
            .info(TorrentDetailInfoViewModel(
                name: "Seeds",
                value: torrentSubject
                    .map { "\($0.seeds) (\($0.totalSeeds))" }
                    .ui()
                    .eraseToAnyPublisher()
            )),
        ]))

        if !torrent.trackers.isEmpty {
            sections.append(TorrentDetailSection(type: .trackers, items: torrent.trackers.map { .tracker($0) }))
        }

        if !files.isEmpty {
            sections.append(TorrentDetailSection(type: .files, items: files.map {
                .file(DelugeTorrentDetailFileViewModel(fileSubject: $0).eraseToAny())
            }))
        }

        return sections
    }

    func didAppear() {
        if let timer = autoUpdateTimer, timer.isValid {
            return
        }

        timerIntervalObserver = preferences.valuePublisher(for: PreferenceKeys.autoRefreshInterval)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] value in
                self?.configureAutoUpdateTimer(interval: value)
            })
    }

    func didDisappear() {
        autoUpdateTimer?.invalidate()
        timerIntervalObserver?.cancel()
    }

    private func configureAutoUpdateTimer(interval: TimeInterval?) {
        autoUpdateTimer?.invalidate()
        guard let interval = interval, interval > 0 else { return }
        let timer = Timer(fire: Date().advanced(by: interval), interval: interval, repeats: true) { [weak self] in
            self?.updateTimerFired($0)
        }
        RunLoop.main.add(timer, forMode: .common)
        autoUpdateTimer = timer
    }

    @objc
    private func updateTimerFired(_ timer: Timer) {
        refreshFiles()
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &observers)
    }

    func refresh() -> AnyPublisher<Void, Error> {
        return refresher.refreshTorrents()
            .mapError { $0 as Error }
            .flatMap { _ in self.refreshFiles() }
            .ui()
            .handleEvents(receiveCompletion: { [weak self] completion in
                guard case let .failure(error) = completion else { return }
                self?.showError(title: "Update Failed", message: error.localizedDescription)
            })
            .eraseToAnyPublisher()
    }

    private func refreshFiles() -> AnyPublisher<Void, Error> {
        return client.fetchTorrentFiles(hash: torrentSubject.value.hash)
            .handleEvents(receiveOutput: { [weak self] new in
                self?.files.update(with: new.map { ($0.path, $0) })
            })
            .mapError { $0 as Error }
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    func didSelectMoreOptions(from source: PopoverSource) {
        var alert = Alert(title: nil, message: nil, style: .actionSheet)
        alert.addAction(AlertAction(title: "Force Recheck", style: .default) {
            self.recheck()
        })
        alert.addAction(AlertAction(title: "Cancel", style: .cancel))
        eventSubject.send(.alert(alert, source: source))
    }

    private func recheck() {
        client.recheck(hashes: [torrentSubject.value.hash])
            .handleEvents(receiveCompletion: { completion in
                guard case .finished = completion else { return }
                self.refresher.refreshTorrents()
                    .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
                    .store(in: &self.observers)
            })
            .ui()
            .sink(receiveCompletion: { [weak self] completion in
                guard case let .failure(error) = completion else { return }
                self?.showError(title: "Failed to Recheck", message: error.localizedDescription)
            }, receiveValue: { _ in })
            .store(in: &observers)
    }

    func didSelectPause() {
        client.pause(hashes: [torrentSubject.value.hash])
            .handleEvents(receiveCompletion: { completion in
                guard case .finished = completion else { return }
                self.refresher.refreshTorrents()
                    .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
                    .store(in: &self.observers)
            })
            .ui()
            .sink(receiveCompletion: { [weak self] completion in
                guard case let .failure(error) = completion else { return }
                self?.showError(title: "Failed to Pause", message: error.localizedDescription)
            }, receiveValue: { _ in })
            .store(in: &observers)
    }

    func didSelectResume() {
        client.resume(hashes: [torrentSubject.value.hash])
            .handleEvents(receiveCompletion: { completion in
                guard case .finished = completion else { return }
                self.refresher.refreshTorrents()
                    .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
                    .store(in: &self.observers)
            })
            .ui()
            .sink(receiveCompletion: { [weak self] completion in
                guard case let .failure(error) = completion else { return }
                self?.showError(title: "Failed to Resume", message: error.localizedDescription)
            }, receiveValue: { _ in })
            .store(in: &observers)
    }

    func didSelectRemove(from source: PopoverSource) {
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
        client.remove(hashes: [torrentSubject.value.hash], removeData: removeData)
            .handleEvents(receiveCompletion: { completion in
                guard case .finished = completion else { return }
                self.refresher.refreshTorrents()
                    .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
                    .store(in: &self.observers)
            })
            .ui()
            .sink(receiveCompletion: { [weak self] completion in
                guard case let .failure(error) = completion else { return }
                self?.showError(title: "Failed to Remove", message: error.localizedDescription)
            }, receiveValue: { _ in })
            .store(in: &observers)
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
