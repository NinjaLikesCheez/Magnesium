import Combine

/**
 A `Coordinator` is used to manage the navigation layer. Coordinators require a `presentable` which provides a
 view controller to be presented by a parent coordinator.
 */
public protocol Coordinator: AnyObject {
    /// The type of event emitted by this coordinator.
    associatedtype Event

    /// Combine observers used for child coordinators.
    var observers: [AnyCancellable] { get set }
    /// The child coordinators owned by this coordinator.
    var childCoordinators: [AnyHashable: AnyCoordinator] { get set }
    /// The view controller to be presented.
    var presentable: Presentable { get }
    /// A publisher of events that this coordinator can emit.
    var events: AnyPublisher<Event, Never> { get }
}

public extension Coordinator {
    /// Adds a child coordinator and automatically removes it when its presentable is dismissed.
    /// - Parameter coordinator: The child coordinator to add.
    /// - Parameter eventHandler: The event handler for the child coordinator.
    func addChildCoordinator<C: Coordinator>(_ coordinator: C, eventHandler: @escaping (C, C.Event) -> Void) {
        childCoordinators[ObjectIdentifier(coordinator)] = AnyCoordinator(coordinator)
        coordinator.presentable.didDismiss
            .sink(receiveCompletion: { [weak self, weak coordinator] _ in
                guard let coordinator = coordinator else { return }
                self?.removeChildCoordinator(coordinator)
            }, receiveValue: { _ in })
            .store(in: &observers)
        coordinator.events
            .sink { [weak coordinator] event in
                guard let coordinator = coordinator else { return }
                eventHandler(coordinator, event)
            }
            .store(in: &observers)
    }

    /// Adds a child coordinator and automatically removes it when its presentable is dismissed.
    /// - Parameter coordinator: The child coordinator to add.
    func addChildCoordinator<C: Coordinator>(_ coordinator: C) where C.Event == Never {
        childCoordinators[ObjectIdentifier(coordinator)] = AnyCoordinator(coordinator)
        coordinator.presentable.didDismiss
            .sink(receiveCompletion: { [weak self, weak coordinator] _ in
                guard let coordinator = coordinator else { return }
                self?.removeChildCoordinator(coordinator)
            }, receiveValue: { _ in })
            .store(in: &observers)
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
