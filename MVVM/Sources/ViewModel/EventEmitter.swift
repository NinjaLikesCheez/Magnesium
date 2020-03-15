import Combine

/// An `EventEmitter` can emit events over time.
public protocol EventEmitter {
    /// The type of event being emitted.
    associatedtype Event
    /// A publisher that emits values of type `Event`.
    var events: AnyPublisher<Event, Never> { get }
}
