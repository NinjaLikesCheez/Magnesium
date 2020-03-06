import Combine

/// An `EventEmitter` emits events over time.
public protocol EventEmitter {
    /// The type of event being emitted.
    associatedtype Event
    /// The event publisher.
    var events: AnyPublisher<Event, Never> { get }
}
