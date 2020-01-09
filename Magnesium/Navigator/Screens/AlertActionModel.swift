//
//  AlertActionModel.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-08.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Foundation

struct AlertActionModel {
    enum Style {
        case `default`
        case cancel
        case destructive
    }

    var title: String?
    var style: Style
    var handler: (() -> Void)?
}
