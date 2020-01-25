import Combine

/**
 A `Coordinator` is used to manage the navigation layer. Coordinators require a `presentable` which provides a
 view controller to be presented by a parent coordinator.
 */
public protocol Coordinator: AnyObject {
    /// The child coordinators owned by this coordinator.
    var childCoordinators: [Coordinator] { get set }
    /// Combine observers used for child coordinators.
    var observers: [AnyCancellable] { get set }
    /// The view controller to be presented.
    var presentable: Presentable { get }
}

public extension Coordinator {
    /// Adds a child coordinator and automatically removes it when its presentable is dismissed.
    /// - Parameter coordinator: The child coordinator to add.
    func addChildCoordinator(_ coordinator: Coordinator) {
        childCoordinators.append(coordinator)
        coordinator.presentable
            .didDismiss
            .sink(receiveCompletion: { [weak self, weak coordinator] _ in
                guard let coordinator = coordinator else { return }
                self?.removeChildCoordinator(coordinator)
            }, receiveValue: { _ in })
            .store(in: &observers)
    }

    /// Removes a child coordinator.
    /// - Parameter coordinator: The coordinator to remove.
    func removeChildCoordinator(_ coordinator: Coordinator) {
        childCoordinators.removeAll { $0 === coordinator || !$0.presentable.isInViewHierarchy }
    }

    /// Removes any child coordinators that are no longer in the view hierarchy.
    func removeChildrenIfNeeded() {
        childCoordinators.removeAll { !$0.presentable.isInViewHierarchy }
    }
}
