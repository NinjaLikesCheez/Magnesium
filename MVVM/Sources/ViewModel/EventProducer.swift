import Combine

/// An `EventProducer` emits events over time.
public protocol EventProducer {
    associatedtype Event
    /// The event publisher.
    var events: AnyPublisher<Event, Never> { get }
}
