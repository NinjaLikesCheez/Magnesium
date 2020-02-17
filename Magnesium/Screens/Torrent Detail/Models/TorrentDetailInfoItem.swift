//
//  TorrentDetailInfoItem.swift
//  Magnesium
//
//  Created by James Hurst on 2020-02-16.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine

struct TorrentDetailInfoItem: Identifiable {
    var name: String
    var value: AnyPublisher<String, Never>
    var expandedValue: AnyPublisher<String, Never>?

    var id: String {
        return name
    }
}
