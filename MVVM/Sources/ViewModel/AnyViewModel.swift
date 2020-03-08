/// A type-erased `ViewModel`.
public class AnyViewModel<ViewEvent, ViewState>: ViewModel {
    private let _state: () -> ViewState
    private let _handle: (ViewEvent) -> Void
    public let base: Any
    public var state: ViewState { _state() }

    public init<Base: ViewModel>(
        _ base: Base
    ) where Base.ViewEvent == ViewEvent, Base.ViewState == ViewState {
        self.base = base
        _state = { base.state }
        _handle = base.handle
    }

    public func handle(_ event: ViewEvent) {
        _handle(event)
    }
}
