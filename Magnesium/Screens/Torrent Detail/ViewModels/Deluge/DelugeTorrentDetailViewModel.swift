//
//  DelugeTorrentDetailViewModel.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-07.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import Navigator
import UIKit

final class DelugeTorrentDetailViewModel: TorrentDetailViewModel {
    private typealias TorrentSubject = CurrentValueSubject<DelugeTorrent, Never>
    private typealias FileSubject = CurrentValueSubject<DelugeTorrentFile, Never>
    private typealias FileMap = [String: FileSubject]

    private let client: DelugeClient
    private let refresher: DelugeRefreshable
    private let torrentSubject: TorrentSubject
    private let fileMap = CurrentValueSubject<FileMap?, Never>(nil)
    private var observers = [AnyCancellable]()

    var navigator: Navigator?
    let sections: AnyPublisher<[(TorrentDetailSection, [TorrentDetailItem])], Never>

    private static func createSections(
        torrentSubject: TorrentSubject,
        torrent: DelugeTorrent,
        fileMap: FileMap?
    ) -> [(TorrentDetailSection, [TorrentDetailItem])] {
        var sections = [(TorrentDetailSection, [TorrentDetailItem])]()
        sections.append((.header, [
            .header(DelugeTorrentDetailHeaderViewModel(torrentSubject: torrentSubject).eraseToAny()),
        ]))
        sections.append((.info, [
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
            sections.append((.trackers, torrent.trackers.map { .tracker($0) }))
        }

        if let fileMap = fileMap {
            let items = fileMap.values
                .sorted {
                    $0.value.path.compare(
                        $1.value.path,
                        options: [.numeric, .caseInsensitive]
                    ) == .orderedDescending
                }
                .map {
                    TorrentDetailItem.file(DelugeTorrentDetailFileViewModel(fileSubject: $0).eraseToAny())
                }
            sections.append((.files, items))
        }

        return sections
    }

    init(
        torrentSubject: CurrentValueSubject<DelugeTorrent, Never>,
        client: DelugeClient,
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
            .ui()
            .eraseToAnyPublisher()

        refreshFiles()
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &observers)
    }

    func refresh() -> AnyPublisher<Never, Error> {
        return refresher.refresh()
            .flatMap { _ in self.refreshFiles() }
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
        var alert = AlertModel(title: nil, message: nil, style: .actionSheet)
        alert.popoverSource = source
        alert.actions.append(AlertActionModel(title: "Force Recheck", style: .default) {
            self.client.recheck(hash: hash)
                .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
                .store(in: &self.observers)
        })
        alert.actions.append(AlertActionModel(title: "Cancel", style: .cancel, handler: nil))
        navigator?.present(AlertScreen(alert), animated: true)
    }

    func didSelectPause() {
        client.pause(hash: torrentSubject.value.hash)
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &observers)
    }

    func didSelectResume() {
        client.resume(hash: torrentSubject.value.hash)
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &observers)
    }

    func didSelectRemove(from source: PopoverSource) {
        let hash = torrentSubject.value.hash
        var alert = AlertModel(title: nil, message: nil, style: .actionSheet)
        alert.popoverSource = source
        alert.actions.append(AlertActionModel(title: "Keep Data", style: .default) {
            self.client.remove(hash: hash, removeData: false)
                .ui()
                .sink(receiveCompletion: { _ in
                    self.dismiss()
                }, receiveValue: { _ in })
                .store(in: &self.observers)
        })
        alert.actions.append(AlertActionModel(title: "Remove Data", style: .destructive, handler: {
            self.client.remove(hash: hash, removeData: true)
                .ui()
                .sink(receiveCompletion: { _ in
                    self.dismiss()
                }, receiveValue: { _ in })
                .store(in: &self.observers)
        }))
        alert.actions.append(AlertActionModel(title: "Cancel", style: .cancel, handler: nil))
        navigator?.present(AlertScreen(alert), animated: true)
    }

    private func dismiss() {
        guard let navigator = navigator else { return }
        let dismissed = navigator.popNestedDetail(animated: true)
        if !dismissed {
            navigator.showDetail(Screens.Torrents.emptyDetail)
        }
    }
}
