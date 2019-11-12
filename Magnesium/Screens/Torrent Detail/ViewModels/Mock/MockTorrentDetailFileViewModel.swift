//
//  MockTorrentDetailFileViewModel.swift
//  Magnesium
//
//  Created by James Hurst on 2019-12-30.
//  Copyright © 2019 James Hurst. All rights reserved.
//

import Combine
import UIKit

struct MockTorrentDetailFileViewModel: TorrentDetailFileViewModel {
    let name: String
    let detail: AnyPublisher<String, Never>
    let progress: AnyPublisher<String, Never>

    static func == (lhs: MockTorrentDetailFileViewModel, rhs: MockTorrentDetailFileViewModel) -> Bool {
        return lhs.name == rhs.name
    }

    init(fileSubject: CurrentValueSubject<MockTorrentFile, Never>) {
        let file = fileSubject.value
        name = file.name
        detail = Just("").eraseToAnyPublisher()
        progress = fileSubject
            .map { torrent in
                "\(Int(torrent.progress * 100))%"
            }
            .ui()
            .eraseToAnyPublisher()
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}
