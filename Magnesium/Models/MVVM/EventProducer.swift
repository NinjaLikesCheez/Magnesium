//
//  EventProducer.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-28.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine

/// An `EventProducer` emits events over time.
public protocol EventProducer {
    associatedtype Event
    /// The event publisher.
    var events: AnyPublisher<Event, Never> { get }
}
