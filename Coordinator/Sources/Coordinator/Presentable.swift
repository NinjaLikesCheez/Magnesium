//
//  Presentable.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-17.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine

public protocol Presentable {
    var didDismiss: AnyPublisher<Void, Never> { get }
}
