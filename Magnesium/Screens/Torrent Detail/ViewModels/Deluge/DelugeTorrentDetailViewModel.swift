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
    private static let refreshDelay: TimeInterval = 1

    private let client: DelugeClient
    private let refresher: DelugeRefreshable
    private let torrentSubject: CurrentValueSubject<DelugeTorrent, Never>
    private var observers = [AnyCancellable]()
    private var autoUpdateTimer: Timer?

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

    let sections: AnyPublisher<[TorrentDetailSection], Never>
    weak var coordinator: TorrentDetailCoordinator?

    init(
        torrentSubject: CurrentValueSubject<DelugeTorrent, Never>,
        client: DelugeClient,
        preferences: Preferences,
        refresher: DelugeRefreshable
    ) {
        self.torrentSubject = torrentSubject
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

        preferences.valuePublisher(for: PreferenceKeys.autoRefreshInterval)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] value in
                self?.configureAutoUpdateTimer(interval: value)
            })
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
                    .map { $0.eta > 0 ? DateFormatters.etaFormatter.string(from: $0.eta) ?? "" : "∞" }
                    .ui()
                    .eraseToAnyPublisher()
            )),
            .info(TorrentDetailInfoViewModel(
                name: "Ratio",
                value: torrentSubject
                    .map { !$0.ratio.isNaN ? String(format: "%.3f", $0.ratio) : "∞" }
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

    func refresh() -> AnyPublisher<Never, Error> {
        return refresher.refreshTorrents()
            .mapError { $0 as Error }
            .flatMap { _ in self.refreshFiles() }
            .ui()
            .handleEvents(receiveCompletion: { [weak self] completion in
                switch completion {
                case let .failure(error):
                    self?.displayError(error, title: "Update Failed")
                case .finished:
                    break
                }
            })
            .eraseToAnyPublisher()
    }

    private func refreshFiles() -> AnyPublisher<Never, Error> {
        return client.getTorrentFiles(hash: torrentSubject.value.hash)
            .handleEvents(receiveOutput: { new in
                self.files.update(with: new.map { ($0.path, $0) })
            })
            .mapError { $0 as Error }
            .ignoreOutput()
            .eraseToAnyPublisher()
    }

    func didSelectMoreOptions(from source: PopoverSource) {
        let hash = torrentSubject.value.hash
        var alert = Alert(title: nil, message: nil, style: .actionSheet)
        alert.actions.append(AlertAction(title: "Force Recheck", style: .default) {
            self.client.recheck(hash: hash)
                .collect()
                .delay(
                    for: .seconds(DelugeTorrentDetailViewModel.refreshDelay),
                    scheduler: DispatchQueue.global(qos: .userInitiated)
                )
                .flatMap { _ in self.refresher.refreshTorrents() }
                .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
                .store(in: &self.observers)
        })
        alert.actions.append(AlertAction(title: "Cancel", style: .cancel, handler: nil))
        coordinator?.showAlert(alert, from: source)
    }

    func didSelectPause() {
        client.pause(hash: torrentSubject.value.hash)
            .collect()
            .delay(
                for: .seconds(DelugeTorrentDetailViewModel.refreshDelay),
                scheduler: DispatchQueue.global(qos: .userInitiated)
            )
            .flatMap { _ in self.refresher.refreshTorrents() }
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &observers)
    }

    func didSelectResume() {
        client.resume(hash: torrentSubject.value.hash)
            .collect()
            .delay(
                for: .seconds(DelugeTorrentDetailViewModel.refreshDelay),
                scheduler: DispatchQueue.global(qos: .userInitiated)
            )
            .flatMap { _ in self.refresher.refreshTorrents() }
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &observers)
    }

    func didSelectRemove(from source: PopoverSource) {
        let hash = torrentSubject.value.hash
        var alert = Alert(title: nil, message: nil, style: .actionSheet)
        alert.actions.append(AlertAction(title: "Keep Data", style: .default) {
            self.client.remove(hash: hash, removeData: false)
                .collect()
                .delay(
                    for: .seconds(DelugeTorrentDetailViewModel.refreshDelay),
                    scheduler: DispatchQueue.global(qos: .userInitiated)
                )
                .flatMap { _ in self.refresher.refreshTorrents() }
                .ui()
                .sink(receiveCompletion: { [weak self] _ in
                    self?.coordinator?.complete()
                }, receiveValue: { _ in })
                .store(in: &self.observers)
        })
        alert.actions.append(AlertAction(title: "Remove Data", style: .destructive, handler: {
            self.client.remove(hash: hash, removeData: true)
                .collect()
                .delay(
                    for: .seconds(DelugeTorrentDetailViewModel.refreshDelay),
                    scheduler: DispatchQueue.global(qos: .userInitiated)
                )
                .flatMap { _ in self.refresher.refreshTorrents() }
                .ui()
                .sink(receiveCompletion: { [weak self] _ in
                    self?.coordinator?.complete()
                }, receiveValue: { _ in })
                .store(in: &self.observers)
        }))
        alert.actions.append(AlertAction(title: "Cancel", style: .cancel, handler: nil))
        coordinator?.showAlert(alert, from: source)
    }

    private func displayError(_ error: Error, title: String) {
        var alert = Alert(
            title: title,
            message: error.localizedDescription,
            style: .alert
        )
        alert.actions.append(AlertAction(title: "OK", style: .default, handler: nil))
        coordinator?.showAlert(alert)
    }
}
