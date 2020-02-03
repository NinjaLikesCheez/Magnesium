//
//  DelugeTorrentListItemViewModel.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-07.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import UIKit
import ViewModel

struct DelugeTorrentListItemViewModel: ViewModel, Identifiable {
    let hash: String
    let state: TorrentListItemViewState

    var id: String {
        return hash
    }

    init(subject: CurrentValueSubject<DelugeTorrent, Never>) {
        hash = subject.value.hash
        let ui = subject.ui()
        state = TorrentListItemViewState(
            name: ui.map(\.name).eraseToAnyPublisher(),
            progress: ui.map(\.progress).eraseToAnyPublisher(),
            progressColor: ui.map(\.standardState).map(\.displayColor).eraseToAnyPublisher(),
            state: ui.map(\.standardState).map(\.displayString).eraseToAnyPublisher(),
            speed: ui.map(\.speedString).eraseToAnyPublisher(),
            progressString: ui.map(\.progressString).eraseToAnyPublisher(),
            ratioOrETA: ui.map(\.ratioOrETAString).eraseToAnyPublisher()
        )
    }
}
