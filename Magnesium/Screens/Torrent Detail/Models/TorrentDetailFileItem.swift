//
//  TorrentDetailFileItem.swift
//  Magnesium
//
//  Created by James Hurst on 2019-12-30.
//  Copyright © 2019 James Hurst. All rights reserved.
//

import Combine

struct TorrentDetailFileItem: Identifiable {
    let id: Int
    var name: AnyPublisher<String, Never>
    var size: AnyPublisher<String, Never>
    var progress: AnyPublisher<String, Never>

    init<F: StandardTorrentFile>(file: CurrentValueSubject<F, Never>) {
        id = file.value.index
        name = file.map(\.name).ui().eraseToAnyPublisher()
        size = file.map { Formatters.bytes.string(fromByteCount: $0.size) }.ui().eraseToAnyPublisher()
        progress = file.map { Formatters.percentage.string(for: $0.progress) ?? "" }.ui().eraseToAnyPublisher()
    }
}
