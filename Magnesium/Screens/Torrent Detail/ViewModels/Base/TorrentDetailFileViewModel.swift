//
//  TorrentDetailFileViewModel.swift
//  Magnesium
//
//  Created by James Hurst on 2019-12-30.
//  Copyright © 2019 James Hurst. All rights reserved.
//

import Combine
import ViewModel

typealias AnyTorrentDetailFileViewModel = AnyViewModel<Never, TorrentDetailFileViewState>

struct TorrentDetailFileViewState {
    var name: AnyPublisher<String, Never>
    var size: AnyPublisher<String, Never>
    var progress: AnyPublisher<String, Never>
}

struct StandardTorrentDetailFileViewModel<T: StandardTorrentFile>: ViewModel, Identifiable {
    let id: Int
    let state: TorrentDetailFileViewState

    init(subject: CurrentValueSubject<T, Never>) {
        id = subject.value.index
        let ui = subject.ui()
        state = TorrentDetailFileViewState(
            name: ui.map(\.name).eraseToAnyPublisher(),
            size: ui.map { Formatters.bytes.string(fromByteCount: $0.size) }.eraseToAnyPublisher(),
            progress: ui.map { Formatters.percentage.string(for: $0.progress) ?? "" }.eraseToAnyPublisher()
        )
    }
}
