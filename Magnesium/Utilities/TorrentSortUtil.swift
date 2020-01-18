//
//  TorrentSortUtil.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-17.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import Foundation

protocol SortableTorrent {
    var hash: String { get }
    var name: String { get }
    var dateAdded: Date { get }
    var downloadRate: Int { get }
    var uploadRate: Int { get }
}

enum TorrentSortUtil {
    static func sort<T: SortableTorrent>(
        _ torrents: [CurrentValueSubject<T, Never>],
        using sortOption: SortOption
    ) -> [CurrentValueSubject<T, Never>] {
        let compare: (SortableTorrent, SortableTorrent) -> ComparisonResult
        switch sortOption.property {
        case .name:
            compare = { $0.name.compare($1.name, options: [.numeric, .caseInsensitive]) }
        case .dateAdded:
            compare = { $0.dateAdded.compare($1.dateAdded) }
        case .downloadSpeed:
            compare = {
                $0.downloadRate == $1.downloadRate
                    ? .orderedSame
                    : $0.downloadRate < $1.downloadRate ? .orderedAscending : .orderedDescending
            }
        case .uploadSpeed:
            compare = {
                $0.uploadRate == $1.uploadRate
                    ? .orderedSame
                    : $0.uploadRate < $1.uploadRate ? .orderedAscending : .orderedDescending
            }
        }

        return torrents.sorted { subject1, subject2 -> Bool in
            let obj1 = subject1.value
            let obj2 = subject2.value
            switch compare(obj1, obj2) {
            case .orderedAscending:
                return sortOption.direction == .ascending
            case .orderedDescending:
                return sortOption.direction == .descending
            case .orderedSame:
                if sortOption.property != .name {
                    let result = obj1.name.compare(obj2.name, options: [.numeric, .caseInsensitive])
                    switch result {
                    case .orderedAscending:
                        return true
                    case .orderedDescending:
                        return false
                    case .orderedSame:
                        break
                    }
                }

                return obj1.hash < obj2.hash
            }
        }
    }
}
