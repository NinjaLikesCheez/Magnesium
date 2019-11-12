//
//  TorrentDetailItem.swift
//  Magnesium
//
//  Created by James Hurst on 2019-12-25.
//  Copyright © 2019 James Hurst. All rights reserved.
//

import Combine
import Foundation

enum TorrentDetailItem: Hashable {
    case header(AnyTorrentDetailHeaderViewModel)
    case info(TorrentDetailInfoViewModel)
    case tracker(String)
    case file(AnyTorrentDetailFileViewModel)
}
