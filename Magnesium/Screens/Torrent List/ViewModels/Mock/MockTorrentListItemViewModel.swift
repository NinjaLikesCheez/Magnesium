//
//  MockTorrentListItemViewModel.swift
//  Magnesium
//
//  Created by James Hurst on 2019-11-14.
//  Copyright © 2019 James Hurst. All rights reserved.
//

import Combine
import UIKit

struct MockTorrentListItemViewModel: TorrentListItemViewModel {
    let id: Int
    let name: AnyPublisher<String, Never>
    let progress: AnyPublisher<Float, Never>
    let progressColor: AnyPublisher<UIColor, Never>
    let detail1: AnyPublisher<String, Never>
    let detail2: AnyPublisher<String, Never>
    let detail3: AnyPublisher<String, Never>
    let detail4: AnyPublisher<String, Never>

    static func == (lhs: MockTorrentListItemViewModel, rhs: MockTorrentListItemViewModel) -> Bool {
        return lhs.id == rhs.id
    }

    init(torrentSubject: CurrentValueSubject<MockTorrent, Never>) {
        let torrent = torrentSubject.value
        id = torrent.id
        name = torrentSubject
            .map(\.name)
            .ui()
            .eraseToAnyPublisher()
        progress = torrentSubject
            .map(\.progress)
            .ui()
            .eraseToAnyPublisher()
        progressColor = torrentSubject
            .map(\.state)
            .map { $0.displayColor }
            .ui()
            .eraseToAnyPublisher()
        detail1 = torrentSubject
            .map(\.state)
            .map { $0.displayString }
            .ui()
            .eraseToAnyPublisher()
        detail2 = torrentSubject
            .map(\.speedDisplayString)
            .ui()
            .eraseToAnyPublisher()
        detail3 = torrentSubject
            .map(\.progressDisplayString)
            .ui()
            .eraseToAnyPublisher()
        detail4 = torrentSubject
            .map { torrent in
                if torrent.state == .downloading {
                    return torrent.eta > 0
                        ? DateFormatters.etaFormatter.string(from: torrent.eta) ?? ""
                        : "∞"
                } else {
                    return "Ratio: \(!torrent.ratio.isNaN ? String(format: "%.1f", torrent.ratio) : "∞")"
                }
            }
            .ui()
            .eraseToAnyPublisher()
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
