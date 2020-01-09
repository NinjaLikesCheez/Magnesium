//
//  AlertViewModel.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-08.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Foundation

struct AlertModel {
    enum Style {
        case actionSheet
        case alert
    }

    var title: String?
    var message: String?
    var style: Style
    var actions = [AlertActionModel]()
    var popoverSource: PopoverSource?

    init(title: String?, message: String?, style: Style) {
        self.title = title
        self.message = message
        self.style = style
    }
}
