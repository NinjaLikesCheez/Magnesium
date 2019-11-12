//
//  DefaultNavigator.swift
//  Magnesium
//
//  Created by James Hurst on 2019-12-19.
//  Copyright © 2019 James Hurst. All rights reserved.
//

import UIKit

final class DefaultNavigator: Navigator {
    private var presentationStack: [PresentationContext]

    private var currentContext: PresentationContext? {
        guard let last = presentationStack.last else { return nil }

        guard last.isValid else {
            presentationStack.removeLast()
            return self.currentContext
        }

        return last
    }

    init(presentationContext: PresentationContext) {
        presentationStack = [presentationContext]
    }

    func push(_ navigatable: Navigatable, animated: Bool) {
        currentContext?.push(navigatable, navigator: self, animated: animated)
    }

    func pop(animated: Bool) {
        currentContext?.pop(animated: animated)
    }

    func present(_ navigatable: Navigatable, style: PresentationStyle, animated: Bool, completion: (() -> Void)?) {
        guard let newContext = currentContext?.present(
            navigatable,
            style: style,
            animated: animated,
            completion: completion
        ) else {
            return
        }
        presentationStack.append(newContext)
    }

    func dismiss(animated: Bool, completion: (() -> Void)?) {
        currentContext?.dismiss(animated: animated, completion: completion)
        presentationStack.removeLast()
    }

    func showDetail(_ navigatable: Navigatable) {
        currentContext?.showDetail(navigatable)
    }
}
