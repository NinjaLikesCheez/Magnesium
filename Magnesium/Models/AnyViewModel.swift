//
//  AnyViewModel.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-28.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine

/// A type erased wrapper for a `ViewModel`.
public class AnyViewModel<ViewEvent, ViewState>: ViewModel, Identifiable {
    private let _state: () -> ViewState
    private let _handle: (ViewEvent) -> Void
    public let base: Any
    public let id: AnyHashable
    public var state: ViewState { _state() }

    public init<Base>(_ base: Base) where Base: ViewModel, Base: Identifiable, Base.ViewEvent == ViewEvent,
        Base.ViewState == ViewState {
        self.base = base
        id = AnyHashable(base.id)
        _state = { base.state }
        _handle = base.handle
    }

    public func handle(_ event: ViewEvent) {
        _handle(event)
    }
}

/// A type erased wrapper for a type that is both a `ViewModel` and `EventProducer`.
public class AnyProducerViewModel<Event, ViewEvent, ViewState>: ViewModel, EventProducer {
    private let _events: () -> AnyPublisher<Event, Never>
    private let _state: () -> ViewState
    private let _handle: (ViewEvent) -> Void
    public let base: Any
    public var state: ViewState { _state() }
    public var events: AnyPublisher<Event, Never> { _events() }

    public init<Base: ViewModel & EventProducer>(
        _ base: Base
    ) where Base.Event == Event, Base.ViewEvent == ViewEvent, Base.ViewState == ViewState {
        self.base = base
        _events = { base.events }
        _state = { base.state }
        _handle = base.handle
    }

    public func handle(_ event: ViewEvent) {
        _handle(event)
    }
}
