//
//  MockTorrentDetailFileViewModel.swift
//  Magnesium
//
//  Created by James Hurst on 2019-12-30.
//  Copyright © 2019 James Hurst. All rights reserved.
//

import Combine

struct MockTorrentDetailFileViewModel: TorrentDetailFileViewModel {
    let name: String
    let size: AnyPublisher<String, Never>
    let progress: AnyPublisher<String, Never>

    static func == (lhs: MockTorrentDetailFileViewModel, rhs: MockTorrentDetailFileViewModel) -> Bool {
        return lhs.name == rhs.name
    }

    init(fileSubject: CurrentValueSubject<MockTorrentFile, Never>) {
        let file = fileSubject.value
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
