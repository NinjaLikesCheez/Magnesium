import Combine

/// A type erased wrapper for a type that is both a `ViewModel` and `EventEmitter`.
public class AnyEmitterViewModel<Event, ViewEvent, ViewState>: ViewModel, EventEmitter {
    private let _events: () -> AnyPublisher<Event, Never>
    private let _state: () -> ViewState
    private let _handle: (ViewEvent) -> Void

    /// The value wrapped by this instance.
    public let base: Any
    public var state: ViewState { _state() }
    public var events: AnyPublisher<Event, Never> { _events() }

    /// Creates a type-erased wrapper for the given value.
    /// - Parameter base: The value to wrap.
    public init<Base: ViewModel & EventEmitter>(
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
