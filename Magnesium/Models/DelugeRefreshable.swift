//
//  DelugeRefreshable.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-08.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine

protocol DelugeRefreshable {
    func refreshTorrents() -> AnyPublisher<Never, DelugeError>
}
