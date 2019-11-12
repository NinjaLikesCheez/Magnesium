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
    var detail1: AnyPublisher<String, Never> { get }
    var detail2: AnyPublisher<String, Never> { get }
    var detail3: AnyPublisher<String, Never> { get }
    var detail4: AnyPublisher<String, Never> { get }
}
