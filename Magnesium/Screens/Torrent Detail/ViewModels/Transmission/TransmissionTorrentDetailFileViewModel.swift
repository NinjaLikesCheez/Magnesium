//
//  TransmissionTorrentDetailFileViewModel.swift
//  Magnesium
//
//  Created by James Hurst on 2020-02-02.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import ViewModel

struct TransmissionTorrentDetailFileViewModel: ViewModel, Identifiable {
    let id: Int
    let state: TorrentDetailFileViewState

    init(subject: CurrentValueSubject<TransmissionTorrentFile, Never>) {
        id = subject.value.index
        let ui = subject.ui()
        state = TorrentDetailFileViewState(
            name: subject.value.name,
            size: ui.map { ByteFormatter.string(fromByteCount: $0.size) }.eraseToAnyPublisher(),
            progress: ui.map { "\(Int(($0.downloaded / $0.size) * 100))%" }.eraseToAnyPublisher()
        )
    }
}
