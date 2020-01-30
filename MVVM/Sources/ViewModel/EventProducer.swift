import Combine

/// An `EventProducer` produces events over time.
public protocol EventProducer {
    associatedtype Event
    /// The event publisher.
    var events: AnyPublisher<Event, Never> { get }
}
