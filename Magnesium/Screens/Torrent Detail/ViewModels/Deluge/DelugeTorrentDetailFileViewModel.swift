//
//  DelugeTorrentDetailFileViewModel.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-08.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import ViewModel

struct DelugeTorrentDetailFileViewModel: ViewModel, Identifiable {
    let id: Int
    let state: TorrentDetailFileViewState

    init(subject: CurrentValueSubject<DelugeTorrentFile, Never>) {
        id = subject.value.index
        let ui = subject.ui()
        state = TorrentDetailFileViewState(
            name: subject.value.name,
            size: ui.map { ByteFormatter.string(fromByteCount: $0.size) }.eraseToAnyPublisher(),
            progress: ui.map { "\(Int($0.progress * 100))%" }.eraseToAnyPublisher()
        )
    }
}
