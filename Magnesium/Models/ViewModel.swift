//
//  ViewModel.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-28.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine

/// A `ViewModel` is able to handle incoming view events and has a view state.
public protocol ViewModel {
    associatedtype ViewEvent
    associatedtype ViewState

    /// The view state. Any values that can change over time will be publishers in the view state.
    var state: ViewState { get }

    /// Handles an incoming view event.
    /// - Parameter event: The view event to be handled.
    func handle(_ event: ViewEvent)
}

public extension ViewModel where ViewEvent == Never {
    func handle(_ event: Never) {}
}

/// An `EventProducer` emits events over time.
public protocol EventProducer {
    associatedtype Event
    /// The event publisher.
    var events: AnyPublisher<Event, Never> { get }
}

/// A type erased wrapper for a `ViewModel`.
public final class AnyViewModel<ViewEvent, ViewState>: ViewModel, Identifiable {
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
public final class AnyProducerViewModel<Event, ViewEvent, ViewState>: ViewModel, EventProducer {
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
