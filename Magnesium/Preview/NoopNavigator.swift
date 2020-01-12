//
//  NoopNavigator.swift
//  Magnesium
//
//  Created by James Hurst on 2019-12-19.
//  Copyright © 2019 James Hurst. All rights reserved.
//

import Foundation
import Navigator

#if DEBUG
    struct NoopNavigator: Navigator {
        func push(_ navigatable: Navigatable, animated: Bool) {}
        func pop(animated: Bool) {}

        func present(
            _ navigatable: Navigatable,
            style: PresentationStyle,
            animated: Bool,
            completion: (() -> Void)?
        ) -> Navigator? {
            return nil
        }

        func dismiss(animated: Bool, completion: (() -> Void)?) {}
        func showDetail(_ navigatable: Navigatable) -> Navigator? { return nil }
        func popNestedDetail(animated: Bool) -> Bool { return false }
    }
#endif
