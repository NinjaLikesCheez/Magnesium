//
//  TorrentDetailHeaderViewState.swift
//  Magnesium
//
//  Created by James Hurst on 2019-12-25.
//  Copyright © 2019 James Hurst. All rights reserved.
//

import Combine
import UIKit
import ViewModel

typealias AnyTorrentDetailHeaderViewModel = AnyViewModel<Never, TorrentDetailHeaderViewState>

struct TorrentDetailHeaderViewState {
    var name: AnyPublisher<String, Never>
    var isActive: AnyPublisher<Bool, Never>
    var progress: AnyPublisher<Float, Never>
    var progressColor: AnyPublisher<UIColor, Never>
    var status: AnyPublisher<String, Never>
    var label: AnyPublisher<String, Never>
}

struct StandardTorrentDetailHeaderViewModel<T: StandardTorrent>: ViewModel, Identifiable {
    let id: String
    let state: TorrentDetailHeaderViewState

    init(subject: CurrentValueSubject<T, Never>) {
        id = subject.value.hash
        let ui = subject.ui()
        state = TorrentDetailHeaderViewState(
            name: ui.map(\.name).eraseToAnyPublisher(),
            isActive: ui.map(\.isActive).eraseToAnyPublisher(),
            progress: ui.map(\.progress).eraseToAnyPublisher(),
            progressColor: ui.map(\.standardState).map(\.displayColor).eraseToAnyPublisher(),
            status: ui
                .map { "\($0.standardState.displayString) (\(String(format: "%.2f", $0.progress * 100))%)" }
                .eraseToAnyPublisher(),
            label: ui.map(\.label).eraseToAnyPublisher()
        )
    }
}
