//
//  DelugeTorrentDetailHeaderViewModel.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-07.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import UIKit

struct DelugeTorrentDetailHeaderViewModel: ViewModel, Identifiable {
    private let hash: String
    let state: TorrentDetailHeaderViewState

    var id: String {
        return hash
    }

    init(torrentSubject: CurrentValueSubject<DelugeTorrent, Never>) {
        let torrent = torrentSubject.value
        hash = torrent.hash
        state = TorrentDetailHeaderViewState(
            name: torrentSubject.map(\.name).ui().eraseToAnyPublisher(),
            isActive: torrentSubject.map(\.isActive).ui().eraseToAnyPublisher(),
            progress: torrentSubject.map(\.progress).ui().eraseToAnyPublisher(),
            progressColor: torrentSubject.map(\.commonState).map(\.displayColor).ui().eraseToAnyPublisher(),
            status: torrentSubject
                .map { "\($0.commonState.displayString) (\(String(format: "%.2f", $0.progress * 100))%)" }
                .ui()
                .eraseToAnyPublisher()
        )
    }
}
