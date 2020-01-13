//
//  TorrentDetailFileViewModel.swift
//  Magnesium
//
//  Created by James Hurst on 2019-12-30.
//  Copyright © 2019 James Hurst. All rights reserved.
//

import Combine

protocol TorrentDetailFileViewModel: Hashable {
    var name: String { get }
    var size: AnyPublisher<String, Never> { get }
    var progress: AnyPublisher<String, Never> { get }
}
