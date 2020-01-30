//
//  TorrentDetailHeaderViewState.swift
//  Magnesium
//
//  Created by James Hurst on 2019-12-25.
//  Copyright © 2019 James Hurst. All rights reserved.
//

import Combine
import UIKit
import ViewModel

typealias AnyTorrentDetailHeaderViewModel = AnyViewModel<Never, TorrentDetailHeaderViewState>

struct TorrentDetailHeaderViewState {
    var name: AnyPublisher<String, Never>
    var isActive: AnyPublisher<Bool, Never>
    var progress: AnyPublisher<Float, Never>
    var progressColor: AnyPublisher<UIColor, Never>
    var status: AnyPublisher<String, Never>
}
