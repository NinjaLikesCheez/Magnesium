//
//  Navigator.swift
//  Navigator
//
//  Created by James Hurst on 2019-12-19.
//  Copyright © 2019 James Hurst. All rights reserved.
//

import Foundation

/**
 A Navigator is used to display navigatable elements.

 A "navigation stack" refers to pushed and popped navigatables. An example of this would be view controllers in a
 UINavigationController.

 A "presentation stack" refers to presented and dismissed navigatables.

 Navigation operations such as push and pop will occur in the navigation stack for the current navigator.

 Presentation operations such as present and dismiss will be performed on the presentation stack known to the current
 navigator. Presentation stacks are shared between the current navigator and the new navigators it creates.

 When displaying a navigatable in a way that will create a new navigation stack, such as present or showDetail,
 a new navigator is returned. This new navigator should be used by the newly displayed navigatable for its navigation.
 */
public protocol Navigator {
    /// Pushes a navigatable to the navigation stack.
    /// - Parameters:
    ///   - navigatable: The navigatable to push.
    ///   - animated: If the push should be animated.
    func push(_ navigatable: Navigatable, animated: Bool)

    /// Pops the current navigatable in the navigation stack.
    /// - Parameter animated: If the pop should be animated.
    func pop(animated: Bool)

    /// Presents a navigatable.
    /// - Parameters:
    ///   - navigatable: The navigatable to present.
    ///   - style: The presentation style to use.
    ///   - animated: If the presentation should be animated.
    ///   - completion: A handler to run when the presentation is completed.
    /// - Returns: A new navigator for the displayed navigatable to use.
    /// The new navigator will share the same presentation stack as this navigator.
    @discardableResult
    func present(
        _ navigatable: Navigatable,
        style: PresentationStyle,
        animated: Bool,
        completion: (() -> Void)?
    ) -> Navigator?

    /// Dismisses the current navigatable in the presentation stack.
    /// - Parameters:
    ///   - animated: If the dismiss should be animated.
    ///   - completion: A handler to run when the dismiss is completed.
    func dismiss(animated: Bool, completion: (() -> Void)?)

    /// Displays a navigatable as the detail in a split environment.
    /// - Parameter navigatable: The navigatable to display.
    /// - Returns: A new navigator for the displayed navigatable to use.
    /// The new navigator will share the same presentation stack as this navigator.
    @discardableResult
    func showDetail(_ navigatable: Navigatable) -> Navigator?

    /// Pops the detail navigation stack if displayed as a single navigation stack.
    /// - Parameters:
    ///   - animated: If the pop should be animated.
    /// - Returns: Returns true if the detail navigation stack was popped. If false this may indicate that the
    /// split environment is displayed as two separate panes.
    func popDetail(animated: Bool) -> Bool
}

public extension Navigator {
    @discardableResult
    func present(_ navigatable: Navigatable, animated: Bool, completion: (() -> Void)? = nil) -> Navigator? {
        return present(navigatable, style: .automatic, animated: animated, completion: completion)
    }

    func dismiss(animated: Bool) {
        dismiss(animated: animated, completion: nil)
    }
}
