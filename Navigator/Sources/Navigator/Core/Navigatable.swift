import UIKit

/// A view controller that can be displayed.
public protocol Navigatable {
    /// - Returns: The view controller to be displayed.
    func viewController() -> UIViewController?
}
