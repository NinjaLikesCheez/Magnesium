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
        state = TorrentListItemViewState(
            name: subject.map(\.name).ui().eraseToAnyPublisher(),
            progress: subject.map(\.progress).ui().eraseToAnyPublisher(),
            progressColor: subject.map(\.standardState.displayColor).ui().eraseToAnyPublisher(),
            state: subject.map(\.standardState.localizedString).ui().eraseToAnyPublisher(),
            speed: subject.map(\.localizedSpeed).ui().eraseToAnyPublisher(),
            progressString: subject.map(\.localizedProgress).ui().eraseToAnyPublisher(),
            ratioOrETA: subject.map(\.localizedRatioOrETA).ui().eraseToAnyPublisher()
        )
    }
}
