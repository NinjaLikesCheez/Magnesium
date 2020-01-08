//
//  PresentationContext.swift
//  Magnesium
//
//  Created by James Hurst on 2019-12-19.
//  Copyright © 2019 James Hurst. All rights reserved.
//

import UIKit

final class PresentationContext {
    private weak var viewController: UIViewController?

    var isValid: Bool {
        return viewController != nil
    }

    private var navigationController: UINavigationController? {
        if let navigationController = viewController as? UINavigationController {
            return navigationController
        } else {
            return viewController?.navigationController
        }
    }

    private var splitViewController: UISplitViewController? {
        if let splitViewController = viewController as? UISplitViewController {
            return splitViewController
        } else {
            return viewController?.splitViewController
        }
    }

    init(viewController: UIViewController) {
        self.viewController = viewController.navigationController ?? viewController
    }

    func push(_ navigatable: Navigatable, navigator: Navigator, animated: Bool) {
        guard let pushedViewController = navigatable.viewController() else { return }

        if var navigatorConfigurable = navigatable as? NavigatorConfigurable {
            navigatorConfigurable.navigator = navigator
        }

        navigationController?.pushViewController(pushedViewController, animated: animated)
    }

    func pop(animated: Bool) {
        navigationController?.popViewController(animated: animated)
    }

    func present(
        _ navigatable: Navigatable,
        style: PresentationStyle,
        animated: Bool,
        completion: (() -> Void)?
    ) -> PresentationContext? {
        guard let viewController = navigationController ?? self.viewController else { return nil }
        guard let presentedViewController = navigatable.viewController() else { return nil }
        let newContext = PresentationContext(viewController: presentedViewController)

        if var navigatorConfigurable = navigatable as? NavigatorConfigurable {
            navigatorConfigurable.navigator = DefaultNavigator(presentationContext: newContext)
        }

        presentedViewController.modalPresentationStyle = style.modalPresentationStyle

        if case let .popover(source) = style {
            switch source {
            case let .view(view, rect: rect):
                presentedViewController.popoverPresentationController?.sourceView = view
                presentedViewController.popoverPresentationController?.sourceRect = rect
            case let .barButton(barButtonItem):
                presentedViewController.popoverPresentationController?.barButtonItem = barButtonItem
            }
        }

        viewController.present(presentedViewController, animated: animated, completion: completion)
        return newContext
    }

    func dismiss(animated: Bool, completion: (() -> Void)?) {
        viewController?.dismiss(animated: animated, completion: completion)
    }

    func showDetail(_ navigatable: Navigatable) {
        guard let detailViewController = navigatable.viewController() else { return }

        if var navigatorConfigurable = navigatable as? NavigatorConfigurable {
            navigatorConfigurable.navigator = DefaultNavigator(
                presentationContext: PresentationContext(viewController: detailViewController)
            )
        }

        splitViewController?.showDetailViewController(detailViewController, sender: nil)
    }
}

private extension PresentationStyle {
    var modalPresentationStyle: UIModalPresentationStyle {
        switch self {
        case .automatic:
            return .automatic
        case .fullScreen:
            return .fullScreen
        case .pageSheet:
            return .pageSheet
        case .formSheet:
            return .formSheet
        case .currentContext:
            return .currentContext
        case .custom:
            return .custom
        case .overFullScreen:
            return .overFullScreen
        case .overCurrentContext:
            return .overCurrentContext
        case .popover:
            return .popover
        case .none:
            return .none
        }
    }
}
