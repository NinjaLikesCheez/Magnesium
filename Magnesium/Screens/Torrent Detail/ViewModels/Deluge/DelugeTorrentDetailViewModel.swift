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
    private typealias TorrentSubject = CurrentValueSubject<DelugeTorrent, Never>
    private typealias FileSubject = CurrentValueSubject<DelugeTorrentFile, Never>
    private typealias FileMap = [String: FileSubject]
    private static let refreshDelay: TimeInterval = 1

    private let client: DelugeClient
    private let refresher: DelugeRefreshable
    private let torrentSubject: TorrentSubject
    private let fileMap = CurrentValueSubject<FileMap?, Never>(nil)
    private var observers = [AnyCancellable]()
    private var autoUpdateTimer: Timer?

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
            .combineLatest(fileMap)
            .map { torrent, fileMap in
                DelugeTorrentDetailViewModel.createSections(
                    torrentSubject: torrentSubject,
                    torrent: torrent,
                    fileMap: fileMap
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

    private static func createSections(
        torrentSubject: TorrentSubject,
        torrent: DelugeTorrent,
        fileMap: FileMap?
    ) -> [TorrentDetailSection] {
        var sections = [TorrentDetailSection]()
        sections.append(.init(type: .header, items: [
            .header(DelugeTorrentDetailHeaderViewModel(torrentSubject: torrentSubject).eraseToAny()),
        ]))
        sections.append(.init(type: .info, items: [
            .info(TorrentDetailInfoViewModel(
                name: "Size",
                value: torrentSubject
                    .map { torrent in
                        ByteFormatter.string(fromByteCount: torrent.size)
                    }
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
            sections.append(.init(type: .trackers, items: torrent.trackers.map { .tracker($0) }))
        }

        if let fileMap = fileMap {
            let items = fileMap.values
                .sorted {
                    $0.value.path.compare(
                        $1.value.path,
                        options: [.numeric, .caseInsensitive]
                    ) == .orderedAscending
                }
                .map {
                    TorrentDetailItem.file(DelugeTorrentDetailFileViewModel(fileSubject: $0).eraseToAny())
                }
            sections.append(.init(type: .files, items: items))
        }

        return sections
    }

    private func configureAutoUpdateTimer(interval: TimeInterval?) {
        guard let interval = interval, interval > 0 else {
            autoUpdateTimer?.invalidate()
            autoUpdateTimer = nil
            return
        }

        autoUpdateTimer?.invalidate()
        let timer = Timer(
            fireAt: Date().advanced(by: interval),
            interval: interval,
            target: self,
            selector: #selector(updateTimerFired(_:)),
            userInfo: nil,
            repeats: true
        )
        RunLoop.main.add(timer, forMode: .common)
        autoUpdateTimer = timer
    }

    @objc
    private func updateTimerFired(_ timer: Timer) {
        guard timer.isValid else { return }
        refresh()
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &observers)
    }

    func refresh() -> AnyPublisher<Never, Error> {
        return refresher.refreshTorrents()
            .mapError { $0 as Error }
            .flatMap { _ in self.refreshFiles() }
            .ui()
            .eraseToAnyPublisher()
    }

    private func refreshFiles() -> AnyPublisher<Never, Error> {
        return client.getTorrentFiles(hash: torrentSubject.value.hash)
            .map { files -> FileMap in
                files.reduce(into: FileMap()) { map, file in
                    map[file.path] = CurrentValueSubject(file)
                }
            }
            .handleEvents(receiveOutput: { new in
                let current = self.fileMap.value ?? [:]
                self.fileMap.send(
                    current
                        .filter { new[$0.key] != nil }
                        .merging(new) { current, new in
                            current.send(new.value)
                            return current
                        }
                )
            })
            .mapError { $0 as Error }
            .ignoreOutput()
            .eraseToAnyPublisher()
    }

    func didSelectMoreOptions(from source: PopoverSource) {
        let hash = torrentSubject.value.hash
        var alert = Alert(title: nil, message: nil, style: .actionSheet)
        alert.popoverSource = source
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
        coordinator?.showAlert(alert)
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
        alert.popoverSource = source
        alert.actions.append(AlertAction(title: "Keep Data", style: .default) {
            self.client.remove(hash: hash, removeData: false)
                .collect()
                .delay(
                    for: .seconds(DelugeTorrentDetailViewModel.refreshDelay),
                    scheduler: DispatchQueue.global(qos: .userInitiated)
                )
                .flatMap { _ in self.refresher.refreshTorrents() }
                .ui()
                .sink(receiveCompletion: { _ in
                    self.dismiss()
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
                .sink(receiveCompletion: { _ in
                    self.dismiss()
                }, receiveValue: { _ in })
                .store(in: &self.observers)
        }))
        alert.actions.append(AlertAction(title: "Cancel", style: .cancel, handler: nil))
        coordinator?.showAlert(alert)
    }

    private func dismiss() {
        coordinator?.complete()
    }
}
