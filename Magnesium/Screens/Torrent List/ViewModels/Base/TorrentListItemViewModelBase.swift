//
//  TorrentListItemViewModel.swift
//  Magnesium
//
//  Created by James Hurst on 2019-11-12.
//  Copyright © 2019 James Hurst. All rights reserved.
//

import Combine
import UIKit
import ViewModel

typealias AnyTorrentListItemViewModel = AnyViewModel<Never, TorrentListItemViewState>

struct TorrentListItemViewState {
    var name: AnyPublisher<String, Never>
    var progress: AnyPublisher<Float, Never>
    var progressColor: AnyPublisher<UIColor, Never>
    var state: AnyPublisher<String, Never>
    var speed: AnyPublisher<String, Never>
    var progressString: AnyPublisher<String, Never>
    var ratioOrETA: AnyPublisher<String, Never>
}

struct StandardTorrentListItemViewModel<T: StandardTorrent>: ViewModel, Identifiable {
    let hash: String
    let state: TorrentListItemViewState

    var id: String {
        return hash
    }

    init(subject: CurrentValueSubject<T, Never>) {
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
