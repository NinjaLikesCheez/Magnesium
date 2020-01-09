//
//  DelugeTorrentDetailHeaderViewModel.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-07.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import UIKit

struct DelugeTorrentDetailHeaderViewModel: TorrentDetailHeaderViewModel {
    let hash: String
    let name: AnyPublisher<String, Never>
    let progress: AnyPublisher<Float, Never>
    let progressColor: AnyPublisher<UIColor, Never>
    let status: AnyPublisher<String, Never>

    static func == (lhs: DelugeTorrentDetailHeaderViewModel, rhs: DelugeTorrentDetailHeaderViewModel) -> Bool {
        return lhs.hash == rhs.hash
    }

    init(torrentSubject: CurrentValueSubject<DelugeTorrent, Never>) {
        let torrent = torrentSubject.value
        hash = torrent.hash
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
        status = torrentSubject
            .map { torrent in
                "\(torrent.state.displayString) (\(Int(torrent.progress * 100))%)"
            }
            .ui()
            .eraseToAnyPublisher()
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(hash)
    }
}
