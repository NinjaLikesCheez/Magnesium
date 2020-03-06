//
//  TorrentListEvent.swift
//  Magnesium
//
//  Created by James Hurst on 2020-03-05.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine

enum TorrentListEvent {
    case alert(Alert, source: PopoverSource?)
    case activities([Activity], torrents: [StandardTorrent], source: PopoverSource)
    case add(source: PopoverSource, linkSubject: PassthroughSubject<String, Never>)
    case filter(source: PopoverSource, labels: CurrentValueSubject<[StandardLabel], Never>)
    case detail(viewModel: AnyTorrentDetailViewModel)
    case settings
    case moveDownloadFolder(currentPath: String?, subject: PassthroughSubject<String, Never>)
    case torrentsUpdated(hashes: [String])
}
