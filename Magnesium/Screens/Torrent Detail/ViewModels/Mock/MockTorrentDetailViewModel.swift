//
//  MockTorrentDetailViewModel.swift
//  Magnesium
//
//  Created by James Hurst on 2019-12-19.
//  Copyright © 2019 James Hurst. All rights reserved.
//

import Combine
import UIKit

final class MockTorrentDetailViewModel: TorrentDetailViewModel, NavigatorConfigurable {
    private typealias FileSubject = CurrentValueSubject<MockTorrentFile, Never>
    private typealias FileMap = [String: FileSubject]

    private let torrentSubject: CurrentValueSubject<MockTorrent, Never>
    private let fileMap = CurrentValueSubject<FileMap, Never>([:])
    private let refresher: MockTorrentServerRefreshable
    private var torrentObserver: AnyCancellable?

    let sections: AnyPublisher<[(TorrentDetailSection, [TorrentDetailItem])], Never>
    var navigator: Navigator?

    init(torrentSubject: CurrentValueSubject<MockTorrent, Never>, refresher: MockTorrentServerRefreshable) {
        self.torrentSubject = torrentSubject
        self.refresher = refresher
        sections = torrentSubject
            .combineLatest(fileMap)
            .map { torrent, fileMap in
                var sections = [(TorrentDetailSection, [TorrentDetailItem])]()
                sections.append((.header, [
                    .header(MockTorrentDetailHeaderViewModel(torrentSubject: torrentSubject).eraseToAny()),
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

                if !fileMap.isEmpty {
                    let files = fileMap.values
                        .sorted { $0.value.name.compare($1.value.name, options: [.numeric]) != .orderedDescending }
                        .map {
                            TorrentDetailItem.file(MockTorrentDetailFileViewModel(fileSubject: $0).eraseToAny())
                        }
                    sections.append((.files, files))
                }

                return sections
            }
            .ui()
            .eraseToAnyPublisher()

        torrentObserver = torrentSubject.sink { [weak self] torrent in
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
                self?.refreshFiles(for: torrent)
            }
        }
    }

    func refresh() -> AnyPublisher<Never, Error> {
        return refresher.refresh()
    }

    func pause() {}

    func resume() {}

    func remove() {}

    private func refreshFiles(for torrent: MockTorrent) {
        var new = FileMap()

        var remainingSize = torrent.size
        var index = 0
        let chunkName = torrent.name.lowercased().replacingOccurrences(of: " ", with: ".")
        while remainingSize > 0 {
            let chunkSize: Int64 = 50 * 1024 * 1024
            let suffix = index == 0 ? "rar" : String(format: "r%02d", index - 1)
            let name = "\(chunkName).\(suffix)"
            if remainingSize >= chunkSize {
                remainingSize -= chunkSize
                new[name] = CurrentValueSubject(MockTorrentFile(
                    name: name,
                    size: chunkSize,
                    downloaded: Int64.random(in: 0 ... chunkSize)
                ))
            } else {
                new[name] = CurrentValueSubject(MockTorrentFile(
                    name: name,
                    size: remainingSize,
                    downloaded: Int64.random(in: 0 ... remainingSize)
                ))
                remainingSize -= remainingSize
            }
            index += 1
        }

        fileMap.send(
            fileMap.value
                .filter { new[$0.key] != nil }
                .merging(new) { current, new in
                    current.send(new.value)
                    return current
                }
        )
    }
}
