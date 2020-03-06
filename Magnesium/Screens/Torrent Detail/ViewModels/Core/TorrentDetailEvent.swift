//
//  TorrentDetailEvent.swift
//  Magnesium
//
//  Created by James Hurst on 2020-03-05.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine

enum TorrentDetailEvent {
    case complete
    case alert(Alert, source: PopoverSource?)
    case activities([Activity], torrent: StandardTorrent, source: PopoverSource)
    case moveDownloadFolder(currentPath: String?, subject: PassthroughSubject<String, Never>)
}
