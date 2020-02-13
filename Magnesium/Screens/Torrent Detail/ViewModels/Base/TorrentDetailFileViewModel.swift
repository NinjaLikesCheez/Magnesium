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
        state = TorrentDetailFileViewState(
            name: subject.map(\.name).ui().eraseToAnyPublisher(),
            size: subject.map { Formatters.bytes.string(fromByteCount: $0.size) }.ui().eraseToAnyPublisher(),
            progress: subject.map { Formatters.percentage.string(for: $0.progress) ?? "" }.ui().eraseToAnyPublisher()
        )
    }
}
