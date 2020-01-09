//
//  TorrentListItemViewModel.swift
//  Magnesium
//
//  Created by James Hurst on 2019-11-12.
//  Copyright © 2019 James Hurst. All rights reserved.
//

import Combine
import UIKit

protocol TorrentListItemViewModel: Hashable {
    var name: AnyPublisher<String, Never> { get }
    var progress: AnyPublisher<Float, Never> { get }
    var progressColor: AnyPublisher<UIColor, Never> { get }
    var state: AnyPublisher<String, Never> { get }
    var speed: AnyPublisher<String, Never> { get }
    var progressString: AnyPublisher<String, Never> { get }
    var ratioOrETA: AnyPublisher<String, Never> { get }
}
