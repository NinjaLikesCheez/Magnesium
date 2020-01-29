//
//  TorrentDetailItem.swift
//  Magnesium
//
//  Created by James Hurst on 2019-12-25.
//  Copyright © 2019 James Hurst. All rights reserved.
//

import Combine

enum TorrentDetailItem: Equatable, Hashable {
    case header(AnyTorrentDetailHeaderViewModel)
    case info(String, AnyPublisher<String, Never>)
    case tracker(String)
    case file(AnyTorrentDetailFileViewModel)

    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case let (.header(value1), .header(value2)):
            return value1.id == value2.id
        case let (.info(value1), .info(value2)):
            return value1.0 == value2.0
        case let (.tracker(value1), .tracker(value2)):
            return value1 == value2
        case let (.file(value1), .file(value2)):
            return value1.id == value2.id
        default:
            return false
        }
    }

    func hash(into hasher: inout Hasher) {
        switch self {
        case let .header(value):
            hasher.combine(value.id)
        case let .info(value):
            hasher.combine(value.0)
        case let .tracker(value):
            hasher.combine(value)
        case let .file(value):
            hasher.combine(value.id)
        }
    }
}
