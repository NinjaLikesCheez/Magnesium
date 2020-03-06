//
//  TorrentDetailViewEvent.swift
//  Magnesium
//
//  Created by James Hurst on 2020-03-05.
//  Copyright © 2020 James Hurst. All rights reserved.
//

enum TorrentDetailViewEvent {
    case appear
    case disappear
    case refresh
    case moreOptions(source: PopoverSource)
    case pause
    case resume
    case remove(source: PopoverSource)
}
