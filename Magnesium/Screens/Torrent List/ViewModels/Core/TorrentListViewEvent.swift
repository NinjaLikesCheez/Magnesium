//
//  TorrentListViewEvent.swift
//  Magnesium
//
//  Created by James Hurst on 2020-03-05.
//  Copyright © 2020 James Hurst. All rights reserved.
//

enum TorrentListViewEvent {
    case refresh
    case addSelected(source: PopoverSource)
    case filterSelected(source: PopoverSource)
    case itemSelected(index: Int)
    case settingsSelected
    case search(query: String?)
    case resumeSelected(indices: [Int])
    case pauseSelected(indices: [Int])
    case removeSelected(indices: [Int], source: PopoverSource)
    case moreOptionsSelected(indices: [Int], source: PopoverSource)
    case didBeginEditing
    case didEndEditing
    case multiSelectUpdated(indices: [Int])
}
