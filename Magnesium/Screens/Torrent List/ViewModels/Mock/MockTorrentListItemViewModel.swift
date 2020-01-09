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
    let state: AnyPublisher<String, Never>
    let speed: AnyPublisher<String, Never>
    let progressString: AnyPublisher<String, Never>
    let ratioOrETA: AnyPublisher<String, Never>

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
        state = torrentSubject
            .map(\.state)
            .map { $0.displayString }
            .ui()
            .eraseToAnyPublisher()
        speed = torrentSubject
            .map(\.speedString)
            .ui()
            .eraseToAnyPublisher()
        progressString = torrentSubject
            .map(\.progressString)
            .ui()
            .eraseToAnyPublisher()
        ratioOrETA = torrentSubject
            .map(\.ratioOrETAString)
            .ui()
            .eraseToAnyPublisher()
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
