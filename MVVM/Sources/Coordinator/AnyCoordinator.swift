import Combine

/// A type-erased `Coordinator`.
public final class AnyCoordinator: Coordinator {
    private let _presentable: () -> Presentable
    private let _events: () -> AnyPublisher<Any, Never>
    private let _received: () -> AnyPublisher<Any, Never>
    private let _cancellables: () -> Set<AnyCancellable>
    private let _setCancellables: (Set<AnyCancellable>) -> Void
    private let _childCoordinators: () -> [AnyHashable: AnyCoordinator]
    private let _setChildCoordinators: ([AnyHashable: AnyCoordinator]) -> Void
    private let _handle: (Any) -> Void

    /// The value wrapped by this instance.
    public let base: Any
    public var presentable: Presentable { _presentable() }
    public var events: AnyPublisher<Any, Never> { _events() }
    public var received: AnyPublisher<Any, Never> { _received() }

    public var cancellables: Set<AnyCancellable> {
        get { _cancellables() }
        set { _setCancellables(newValue) }
    }

    public var childCoordinators: [AnyHashable: AnyCoordinator] {
        get { _childCoordinators() }
        set { _setChildCoordinators(newValue) }
    }

    /// Creates a type-erased wrapper for the given `Coordinator`.
    /// - Parameter base: The value to wrap.
    public init<Base>(_ base: Base) where Base: Coordinator {
        self.base = base
        _presentable = { base.presentable }
        _events = { base.events.map { $0 as Any }.eraseToAnyPublisher() }
        _received = { base.received.map { $0 as Any }.eraseToAnyPublisher() }
        _cancellables = { base.cancellables }
        _setCancellables = { base.cancellables = $0 }
        _childCoordinators = { base.childCoordinators }
        _setChildCoordinators = { base.childCoordinators = $0 }
        _handle = {
            guard let event = $0 as? Base.Received else { return }
            base.handle(event)
        }
    }

    public func handle(_ event: Any) {
        _handle(event)
    }
}
