//
//  TorrentDetailHeaderViewModel.swift
//  Magnesium
//
//  Created by James Hurst on 2019-12-25.
//  Copyright © 2019 James Hurst. All rights reserved.
//

import Combine
import UIKit

protocol TorrentDetailHeaderViewModel: Hashable {
    var name: AnyPublisher<String, Never> { get }
    var progress: AnyPublisher<Float, Never> { get }
    var progressColor: AnyPublisher<UIColor, Never> { get }
    var status: AnyPublisher<String, Never> { get }
}
