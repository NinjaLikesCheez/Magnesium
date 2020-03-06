/// A `ViewModel` is able to handle incoming view events and has a view state.
public protocol ViewModel {
    /// The type of event being emitted by the view.
    associatedtype ViewEvent
    /// The type representing the view's state.
    associatedtype ViewState

    /// The view state. Any values that can change over time will be publishers in the view state.
    var state: ViewState { get }

    /// Handles an incoming view event.
    /// - Parameter event: The view event to be handled.
    func handle(_ event: ViewEvent)
}

public extension ViewModel where ViewEvent == Never {
    /// A default implementation for `ViewModel`s whose view emits `Never` events.
    func handle(_ event: Never) {}
}
