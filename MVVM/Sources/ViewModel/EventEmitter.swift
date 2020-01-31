import Combine

/// An `EventEmitter` emits events over time.
public protocol EventEmitter {
    associatedtype Event
    /// The event publisher.
    var events: AnyPublisher<Event, Never> { get }
}
