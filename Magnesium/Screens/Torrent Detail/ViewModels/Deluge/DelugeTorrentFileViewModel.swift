//
//  DelugeTorrentFileViewModel.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-08.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import UIKit

struct DelugeTorrentDetailFileViewModel: TorrentDetailFileViewModel {
    private var path: String
    let name: String
    let size: AnyPublisher<String, Never>
    let progress: AnyPublisher<String, Never>

    static func == (lhs: DelugeTorrentDetailFileViewModel, rhs: DelugeTorrentDetailFileViewModel) -> Bool {
        return lhs.name == rhs.name
    }

    init(fileSubject: CurrentValueSubject<DelugeTorrentFile, Never>) {
        let file = fileSubject.value
        path = file.path
        name = file.name
        size = fileSubject
            .map { ByteFormatter.string(fromByteCount: $0.size) }
            .ui()
            .eraseToAnyPublisher()
        progress = fileSubject
            .map { "\(Int($0.progress * 100))%" }
            .ui()
            .eraseToAnyPublisher()
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}
