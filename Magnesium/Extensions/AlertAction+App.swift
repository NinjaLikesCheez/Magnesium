//
//  AlertAction+App.swift
//  Magnesium
//
//  Created by James Hurst on 2020-02-11.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Foundation

extension AlertAction {
    static func ok() -> AlertAction {
        return AlertAction(title: NSLocalizedString("action_ok", comment: "OK"), style: .default)
    }

    static func cancel() -> AlertAction {
        return AlertAction(title: NSLocalizedString("action_cancel", comment: "Cancel"), style: .cancel)
    }
}
