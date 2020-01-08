//
//  DelugeTorrentDetailViewModel.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-07.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import UIKit

final class DelugeTorrentDetailViewModel: TorrentDetailViewModel, NavigatorConfigurable {
    private let torrentSubject: CurrentValueSubject<DelugeTorrent, Never>

    let sections: AnyPublisher<[(TorrentDetailSection, [TorrentDetailItem])], Never>
    var navigator: Navigator?

    init(torrentSubject: CurrentValueSubject<DelugeTorrent, Never>) {
        self.torrentSubject = torrentSubject
        sections = torrentSubject
            .map { torrent in
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

                return sections
            }
            .ui()
            .eraseToAnyPublisher()
    }

    func refresh() -> AnyPublisher<Void, Error> {
        // TODO:
        Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
}
