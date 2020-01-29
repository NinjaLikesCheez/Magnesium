//
//  DelugeTorrentFileViewModel.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-08.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine

struct DelugeTorrentDetailFileViewModel: ViewModel, Identifiable {
    private var path: String
    let state: TorrentDetailFileViewState

    var id: String {
        return path
    }

    init(fileSubject: CurrentValueSubject<DelugeTorrentFile, Never>) {
        path = fileSubject.value.path
        state = TorrentDetailFileViewState(
            name: fileSubject.value.name,
            size: fileSubject.map { ByteFormatter.string(fromByteCount: $0.size) }.ui().eraseToAnyPublisher(),
            progress: fileSubject.map { "\(Int($0.progress * 100))%" }.ui().eraseToAnyPublisher()
        )
    }
}
