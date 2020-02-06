import Combine
import UIKit

/// A protocol describing a view controller that can be presented.
public protocol Presentable {
    /// A publisher that emits an event when the view controller is dismissed.
    var didDismiss: AnyPublisher<Void, Never> { get }
    /// The view controller to be presented.
    var viewController: UIViewController { get }
}

public extension Presentable {
    /// If the viewController is currently in the view hierarchy.
    var isInViewHierarchy: Bool {
        return viewController.isInViewHierarchy
    }
}
