import Combine

/// A `Coordinator` is used to manage navigation.
public protocol Coordinator: AnyObject {
    /// The type of event emitted by this coordinator.
    associatedtype Event
    /// The type of event received by this coordinator.
    associatedtype Received

    /// Combine observers used for child coordinators.
    var observers: [AnyCancellable] { get set }
    /// The child coordinators owned by this coordinator.
    var childCoordinators: [AnyHashable: AnyCoordinator] { get set }
    /// The view controller to be presented.
    var presentable: Presentable { get }
    /// A publisher of events that this coordinator can emit.
    var events: AnyPublisher<Event, Never> { get }
    /// A publisher that emits events to be received by this coordinator.
    var received: AnyPublisher<Received, Never> { get }

    /// Handles a received event.
    ///
    /// This function will automatically be called if this coordinator was added to a parent
    /// coordinator using `addChildCoordinator`.
    ///
    ///
    /// - Parameter event: The event to handle.
    func handle(_ event: Received)
}

public extension Coordinator {
    /// Adds a child coordinator, automatically removes it when its presentable is dismissed, handles the child
    /// coordinator's events, and sets up the child coordinator to handle it's received events.
    /// - Parameter coordinator: The child coordinator to add.
    /// - Parameter eventHandler: The event handler for the child coordinator.
    func addChildCoordinator<C: Coordinator>(_ coordinator: C, eventHandler: @escaping (C, C.Event) -> Void) {
        childCoordinators[ObjectIdentifier(coordinator)] = AnyCoordinator(coordinator)
        coordinator.presentable.didDismiss
            .sink { [weak self, weak coordinator] _ in
                guard let coordinator = coordinator else { return }
                self?.removeChildCoordinator(coordinator)
            }
            .store(in: &observers)
        coordinator.events
            .sink { [weak coordinator] event in
                guard let coordinator = coordinator else { return }
                eventHandler(coordinator, event)
            }
            .store(in: &observers)
        coordinator.received
            .sink { [weak coordinator] event in
                coordinator?.handle(event)
            }
            .store(in: &observers)
    }

    /// Adds a child coordinator and automatically removes it when its presentable is dismissed.
    /// - Parameter coordinator: The child coordinator to add.
    func addChildCoordinator<C: Coordinator>(_ coordinator: C) where C.Event == Never {
        addChildCoordinator(coordinator, eventHandler: { _, _ in })
    }

    /// Removes a child coordinator.
    /// - Parameter coordinator: The coordinator to remove.
    func removeChildCoordinator<C: Coordinator>(_ coordinator: C) {
        childCoordinators.removeValue(forKey: ObjectIdentifier(coordinator))
        removeChildrenIfNeeded()
    }

    /// Removes any child coordinators that are no longer in the view hierarchy.
    func removeChildrenIfNeeded() {
        childCoordinators = childCoordinators.filter { _, value in
            value.presentable.isInViewHierarchy
        }
    }
}

public extension Coordinator where Received == Never {
    /// A default implementation for `Coordinator`s that receive `Never` events.
    func handle(_ event: Never) {}
}
