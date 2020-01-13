//
//  TorrentDetailInfoViewModel.swift
//  Magnesium
//
//  Created by James Hurst on 2019-12-26.
//  Copyright © 2019 James Hurst. All rights reserved.
//

import Combine

struct TorrentDetailInfoViewModel: Hashable {
    let name: String
    let value: AnyPublisher<String, Never>

    init(name: String, value: AnyPublisher<String, Never>) {
        self.name = name
        self.value = value
    }

    static func == (lhs: TorrentDetailInfoViewModel, rhs: TorrentDetailInfoViewModel) -> Bool {
        return lhs.name == rhs.name
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}
