//
//  TorrentListProvider.swift
//  Magnesium
//
//  Created by James Hurst on 2020-03-05.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import UIKit

protocol TorrentListProvider: AnyObject {
    func detailViewModelForItem(at index: Int) -> AnyTorrentDetailViewModel?
    func contextMenuForItem(at index: Int) -> UIMenu?
    func leadingSwipeActionsConfigurationForItem(at index: Int, source: PopoverSource) -> SwipeActionsConfiguration?
    func trailingSwipeActionsConfigurationForItem(at index: Int, source: PopoverSource) -> SwipeActionsConfiguration?
}
