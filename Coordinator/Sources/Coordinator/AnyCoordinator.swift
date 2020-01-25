import Combine

@inline(never)
private func _abstract(
    file: StaticString = #file,
    line: UInt = #line
) -> Never {
    fatalError("Method must be overridden", file: file, line: line)
}

private class _AnyCoordinatorBoxBase: Coordinator {
    var base: Any { _abstract() }
    var events: AnyPublisher<Any, Never> { _abstract() }
    var presentable: Presentable { _abstract() }

    var observers: [AnyCancellable] {
        get { _abstract() }
        set { _abstract() } // swiftlint:disable:this unused_setter_value
    }

    var childCoordinators: [AnyHashable: AnyCoordinator] {
        get { _abstract() }
        set { _abstract() } // swiftlint:disable:this unused_setter_value
    }
}

private final class _AnyCoordinatorBox<Base: Coordinator>: _AnyCoordinatorBoxBase {
    private let _base: Base

    override var base: Any { _base }
    override var events: AnyPublisher<Any, Never> { _base.events.map { $0 as Any }.eraseToAnyPublisher() }
    override var presentable: Presentable { _base.presentable }

    override var observers: [AnyCancellable] {
        get { _base.observers }
        set { _base.observers = newValue }
    }

    override var childCoordinators: [AnyHashable: AnyCoordinator] {
        get { _base.childCoordinators }
        set { _base.childCoordinators = newValue }
    }

    init(_ base: Base) {
        _base = base
    }
}

public final class AnyCoordinator: Coordinator {
    private let box: _AnyCoordinatorBoxBase

    public var base: Any { box.base }
    public var events: AnyPublisher<Any, Never> { box.events }
    public var presentable: Presentable { box.presentable }

    public var observers: [AnyCancellable] {
        get { box.observers }
        set { box.observers = newValue }
    }

    public var childCoordinators: [AnyHashable: AnyCoordinator] {
        get { box.childCoordinators }
        set { box.childCoordinators = newValue }
    }

    public init<C: Coordinator>(_ coordinator: C) {
        box = _AnyCoordinatorBox(coordinator)
    }
}
