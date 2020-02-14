//
//  AlertAction+App.swift
//  Magnesium
//
//  Created by James Hurst on 2020-02-11.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Foundation

extension AlertAction {
    static var ok: AlertAction {
        return AlertAction(title: L10n.ok, style: .default)
    }

    static var cancel: AlertAction {
        return AlertAction(title: L10n.cancel, style: .cancel)
    }
}
