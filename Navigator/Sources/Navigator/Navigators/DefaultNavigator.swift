import UIKit

/**
 A Navigator operating on a view controller.

 The view controller used to create the navigator can be either a regular view controller or a navigaiton controller.
 If a regular view controller is used then the view controller's `navigationController` property will be used for
 navigation operations such as push and pop.
 */
public final class DefaultNavigator: Navigator {
    private weak var viewController: UIViewController?

    private var navigationController: UINavigationController? {
        guard let navigationController = viewController as? UINavigationController else {
            return viewController?.navigationController
        }

        return navigationController
    }

    /// Creates a new `DefaultNavigator` with the given view controller.
    /// - Parameter viewController: The view controller to use for navigation. This may be either a regular view
    /// controller or a navigation controller. If a regular view controller is used then the view controller's
    /// `navigationController` property will be used for navigation operations such as push and pop.
    public init(viewController: UIViewController) {
        self.viewController = viewController
    }

    public func push(_ navigatable: Navigatable, animated: Bool) {
        guard let viewController = navigatable.viewController() else { return }
        navigationController?.pushViewController(viewController, animated: animated)
    }

    public func pop(animated: Bool) {
        navigationController?.popViewController(animated: animated)
    }

    @discardableResult
    public func present(
        _ navigatable: Navigatable,
        style: PresentationStyle,
        animated: Bool,
        completion: (() -> Void)?
    ) -> Navigator? {
        guard let presentedViewController = navigatable.viewController() else { return nil }
        viewController?.present(presentedViewController, animated: animated, completion: completion)
        return DefaultNavigator(viewController: presentedViewController)
    }

    public func dismiss(animated: Bool, completion: (() -> Void)?) {
        viewController?.dismiss(animated: animated, completion: completion)
    }

    @discardableResult
    public func showMaster(_ navigatable: Navigatable) -> Navigator? {
        guard let masterViewController = navigatable.viewController() else { return nil }
        viewController?.show(masterViewController, sender: nil)
        return DefaultNavigator(viewController: masterViewController)
    }

    @discardableResult
    public func showDetail(_ navigatable: Navigatable) -> Navigator? {
        guard let detailViewController = navigatable.viewController() else { return nil }
        viewController?.showDetailViewController(detailViewController, sender: nil)
        return DefaultNavigator(viewController: detailViewController)
    }

    @discardableResult
    public func popNestedDetail(animated: Bool) -> Bool {
        if let navigationController = navigationController?.navigationController {
            navigationController.popViewController(animated: animated)
            return true
        }

        return false
    }
}
