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
        state = TorrentDetailHeaderViewState(
            name: subject.map(\.name).ui().eraseToAnyPublisher(),
            isActive: subject.map(\.isActive).ui().eraseToAnyPublisher(),
            progress: subject.map(\.progress).ui().eraseToAnyPublisher(),
            progressColor: subject.map(\.standardState.displayColor).ui().eraseToAnyPublisher(),
            status: subject
                .map {
                    let format = NSLocalizedString("torrent_status_and_progress", comment: "{status} ({percentage})")
                    return String.localizedStringWithFormat(
                        format,
                        $0.standardState.localizedString,
                        Formatters.percentage(precision: 2).string(for: $0.progress) ?? ""
                    )
                }
                .ui()
                .eraseToAnyPublisher(),
            label: subject.map(\.label).ui().eraseToAnyPublisher()
        )
    }
}
