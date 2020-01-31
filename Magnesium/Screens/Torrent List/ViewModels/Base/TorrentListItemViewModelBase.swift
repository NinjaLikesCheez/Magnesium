//
//  TorrentListItemViewModel.swift
//  Magnesium
//
//  Created by James Hurst on 2019-11-12.
//  Copyright © 2019 James Hurst. All rights reserved.
//

import Combine
import UIKit
import ViewModel

typealias AnyTorrentListItemViewModel = AnyViewModel<Never, TorrentListItemViewState>

struct TorrentListItemViewState {
    var name: AnyPublisher<String, Never>
    var progress: AnyPublisher<Float, Never>
    var progressColor: AnyPublisher<UIColor, Never>
    var state: AnyPublisher<String, Never>
    var speed: AnyPublisher<String, Never>
    var progressString: AnyPublisher<String, Never>
    var ratioOrETA: AnyPublisher<String, Never>
}
