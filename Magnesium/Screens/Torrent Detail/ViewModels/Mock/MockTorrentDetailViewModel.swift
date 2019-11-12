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
    private let fileMapSubject = CurrentValueSubject<FileMap, Never>([:])
    private let refresher: MockTorrentServerRefreshable
    private var torrentObserver: AnyCancellable?

    let sections: AnyPublisher<[(TorrentDetailSection, [TorrentDetailItem])], Never>
    var navigator: Navigator?

    var torrentDidUpdate: AnyPublisher<Void, Never> {
        return torrentSubject
            .dropFirst()
            .map { _ in () }
            .ui()
            .eraseToAnyPublisher()
    }

    init(torrentSubject: CurrentValueSubject<MockTorrent, Never>, refresher: MockTorrentServerRefreshable) {
        self.torrentSubject = torrentSubject
        self.refresher = refresher
        sections = torrentSubject
            .combineLatest(fileMapSubject)
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
                            .map { torrent in
                                "\(ByteFormatter.string(fromByteCount: torrent.downloadRate))/s"
                            }
                            .ui()
                            .eraseToAnyPublisher()
                    )),
                    .info(TorrentDetailInfoViewModel(
                        name: "Upload Speed",
                        value: torrentSubject
                            .map { torrent in
                                "\(ByteFormatter.string(fromByteCount: torrent.uploadRate))/s"
                            }
                            .ui()
                            .eraseToAnyPublisher()
                    )),
                    .info(TorrentDetailInfoViewModel(
                        name: "Downloaded",
                        value: torrentSubject
                            .map { torrent in
                                ByteFormatter.string(fromByteCount: torrent.downloaded)
                            }
                            .ui()
                            .eraseToAnyPublisher()
                    )),
                    .info(TorrentDetailInfoViewModel(
                        name: "Uploaded",
                        value: torrentSubject
                            .map { torrent in
                                ByteFormatter.string(fromByteCount: torrent.uploaded)
                            }
                            .ui()
                            .eraseToAnyPublisher()
                    )),
                    .info(TorrentDetailInfoViewModel(
                        name: "ETA",
                        value: torrentSubject
                            .map { torrent in
                                torrent.eta > 0 ? DateFormatters.etaFormatter.string(from: torrent.eta) ?? "" : "∞"
                            }
                            .ui()
                            .eraseToAnyPublisher()
                    )),
                    .info(TorrentDetailInfoViewModel(
                        name: "Ratio",
                        value: torrentSubject
                            .map { torrent in
                                !torrent.ratio.isNaN ? String(format: "%.3f", torrent.ratio) : "∞"
                            }
                            .ui()
                            .eraseToAnyPublisher()
                    )),
                    .info(TorrentDetailInfoViewModel(
                        name: "Peers",
                        value: torrentSubject
                            .map { torrent in
                                "\(torrent.peers) (\(torrent.totalPeers))"
                            }
                            .ui()
                            .eraseToAnyPublisher()
                    )),
                    .info(TorrentDetailInfoViewModel(
                        name: "Seeds",
                        value: torrentSubject
                            .map { torrent in
                                "\(torrent.seeds) (\(torrent.totalSeeds))"
                            }
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

    func refresh() -> AnyPublisher<Void, Error> {
        return refresher.refresh()
    }

    private func refreshFiles(for torrent: MockTorrent) {
        var new = FileMap()

        var remainingSize = torrent.size
        var index = 0
        let chunkName = torrent.name.lowercased().replacingOccurrences(of: " ", with: ".")
        while remainingSize > 0 {
            let chunkSize = 50 * 1024 * 1024
            let suffix = index == 0 ? "rar" : String(format: "r%02d", index - 1)
            let name = "\(chunkName).\(suffix)"
            if remainingSize >= chunkSize {
                remainingSize -= chunkSize
                new[name] = CurrentValueSubject(MockTorrentFile(
                    name: name,
                    size: chunkSize,
                    downloaded: Int.random(in: 0 ... chunkSize)
                ))
            } else {
                new[name] = CurrentValueSubject(MockTorrentFile(
                    name: name,
                    size: remainingSize,
                    downloaded: Int.random(in: 0 ... remainingSize)
                ))
                remainingSize -= remainingSize
            }
            index += 1
        }

        fileMapSubject.send(
            fileMapSubject.value
                .filter { new[$0.key] != nil }
                .merging(new) { current, new in
                    current.send(new.value)
                    return current
                }
        )
    }
}
