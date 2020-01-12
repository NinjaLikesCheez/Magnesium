//
//  DefaultNavigator.swift
//  Navigator
//
//  Created by James Hurst on 2019-12-19.
//  Copyright © 2019 James Hurst. All rights reserved.
//

import UIKit

/**
A Navigator operating on a view controller.

 The view controller used to create the navigator can be either a regular view controller or a navigaiton controller. If a regular view controller is used then the view controller's `navigationController` property will be used for navigation operations such as push and pop.
*/
final public class DefaultNavigator: Navigator {
    private class PresentationStack {
        var items: [PresentationContext]

        init(_ context: PresentationContext) {
            items = [context]
        }
    }

    private struct PresentationContext {
        weak var viewController: UIViewController?
    }

    private weak var viewController: UIViewController?
    private var presentationStack: PresentationStack

    private var presentationContext: PresentationContext? {
        guard let last = presentationStack.items.last else { return nil }

        guard last.viewController != nil else {
            presentationStack.items.removeLast()
            return self.presentationContext
        }

        return last
    }

    private var navigationController: UINavigationController? {
        guard let navigationController = viewController as? UINavigationController else {
            return viewController?.navigationController
        }

        return navigationController
    }

    /// Creates a new navigator with the given view controller.
    /// - Parameter viewController: The view controller to use for navigation. This may be either a regular view controller or a navigation controller.
    public convenience init(viewController: UIViewController) {
        self.init(viewController: viewController, presentationStack: nil)
    }

    private init(viewController: UIViewController, presentationStack: PresentationStack?) {
        self.viewController = viewController
        self.presentationStack = presentationStack ?? PresentationStack(
            PresentationContext(viewController: viewController)
        )
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
        guard let viewController = navigatable.viewController() else { return nil }
        presentationContext?.viewController?.present(viewController, animated: animated, completion: completion)
        presentationStack.items.append(PresentationContext(viewController: viewController))
        return DefaultNavigator(viewController: viewController, presentationStack: presentationStack)
    }

    public func dismiss(animated: Bool, completion: (() -> Void)?) {
        presentationContext?.viewController?.dismiss(animated: animated, completion: completion)
        presentationStack.items.removeLast()
    }

    @discardableResult
    public func showDetail(_ navigatable: Navigatable) -> Navigator? {
        guard let viewController = navigatable.viewController() else { return nil }
        self.viewController?.showDetailViewController(viewController, sender: nil)
        return DefaultNavigator(viewController: viewController)
    }

    public func popDetail(animated: Bool) -> Bool {
        if let navigationController = self.navigationController?.navigationController {
            navigationController.popViewController(animated: animated)
            return true
        }

        return false
    }
}
