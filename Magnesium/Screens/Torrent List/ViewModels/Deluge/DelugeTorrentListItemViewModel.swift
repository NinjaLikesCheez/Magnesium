//
//  DelugeTorrentListItemViewModel.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-07.
//  Copyright © 2020 James Hurst. All rights reserved.
//
import Combine
import UIKit

struct DelugeTorrentListItemViewModel: TorrentListItemViewModel {
    let hash: String
    let name: AnyPublisher<String, Never>
    let progress: AnyPublisher<Float, Never>
    let progressColor: AnyPublisher<UIColor, Never>
    let detail1: AnyPublisher<String, Never>
    let detail2: AnyPublisher<String, Never>
    let detail3: AnyPublisher<String, Never>
    let detail4: AnyPublisher<String, Never>

    static func == (lhs: DelugeTorrentListItemViewModel, rhs: DelugeTorrentListItemViewModel) -> Bool {
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
            .map(\.etaOrRatioString)
            .ui()
            .eraseToAnyPublisher()
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(hash)
    }
}
