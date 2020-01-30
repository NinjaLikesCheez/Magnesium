//
//  TransmissionTorrentListItemViewModel.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-14.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import UIKit
import ViewModel

struct TransmissionTorrentListItemViewModel: ViewModel, Identifiable {
    let id: Int
    let state: TorrentListItemViewState

    init(subject: CurrentValueSubject<TransmissionTorrent, Never>) {
        id = subject.value.id
        let ui = subject.ui()
        state = TorrentListItemViewState(
            name: ui.map(\.name).eraseToAnyPublisher(),
            progress: ui.map(\.progress).eraseToAnyPublisher(),
            progressColor: ui.map(\.commonState).map(\.displayColor).eraseToAnyPublisher(),
            state: ui.map(\.commonState).map(\.displayString).eraseToAnyPublisher(),
            speed: ui.map(\.speedString).eraseToAnyPublisher(),
            progressString: ui.map(\.progressString).eraseToAnyPublisher(),
            ratioOrETA: ui.map(\.ratioOrETAString).eraseToAnyPublisher()
        )
    }
}
