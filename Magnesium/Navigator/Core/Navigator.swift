//
//  Navigator.swift
//  Magnesium
//
//  Created by James Hurst on 2019-12-19.
//  Copyright © 2019 James Hurst. All rights reserved.
//

import Foundation

protocol Navigator {
    func push(_ navigatable: Navigatable, animated: Bool)
    func pop(animated: Bool)
    func popToRoot(animated: Bool)
    @discardableResult
    func present(
        _ navigatable: Navigatable,
        style: PresentationStyle,
        animated: Bool,
        completion: (() -> Void)?
    ) -> Navigator?
    func dismiss(animated: Bool, completion: (() -> Void)?)
    @discardableResult
    func showDetail(_ navigatable: Navigatable) -> Navigator?
}

extension Navigator {
    @discardableResult
    func present(_ navigatable: Navigatable, animated: Bool, completion: (() -> Void)? = nil) -> Navigator? {
        return present(navigatable, style: .automatic, animated: animated, completion: completion)
    }

    func dismiss(animated: Bool) {
        dismiss(animated: animated, completion: nil)
    }
}
