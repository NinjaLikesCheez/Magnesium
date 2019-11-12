//
//  MockTorrentHeaderViewModel.swift
//  Magnesium
//
//  Created by James Hurst on 2019-12-25.
//  Copyright © 2019 James Hurst. All rights reserved.
//

import Combine
import UIKit

struct MockTorrentDetailHeaderViewModel: TorrentDetailHeaderViewModel {
    let id: Int
    let name: AnyPublisher<String, Never>
    let progress: AnyPublisher<Float, Never>
    let progressColor: AnyPublisher<UIColor, Never>
    let detail: AnyPublisher<String, Never>

    static func == (lhs: MockTorrentDetailHeaderViewModel, rhs: MockTorrentDetailHeaderViewModel) -> Bool {
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
        detail = torrentSubject
            .map { torrent in
                "\(torrent.state.displayString) (\(Int(torrent.progress * 100))%)"
            }
            .ui()
            .eraseToAnyPublisher()
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
