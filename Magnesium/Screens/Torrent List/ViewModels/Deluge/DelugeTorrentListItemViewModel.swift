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
    let state: AnyPublisher<String, Never>
    let speed: AnyPublisher<String, Never>
    let progressString: AnyPublisher<String, Never>
    let ratioOrETA: AnyPublisher<String, Never>

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
            .map(\.commonState)
            .map { $0.displayColor }
            .ui()
            .eraseToAnyPublisher()
        state = torrentSubject
            .map(\.commonState)
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
        hasher.combine(hash)
    }
}
