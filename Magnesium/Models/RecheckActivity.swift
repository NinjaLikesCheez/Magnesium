//
//  RecheckActivity.swift
//  Magnesium
//
//  Created by James Hurst on 2020-02-09.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import UIKit

final class RecheckActivity: BlockActivity {
    init(handler: @escaping () -> Void) {
        super.init(
            title: "Recheck",
            image: UIImage(systemName: "arrow.clockwise"),
            type: UIActivity.ActivityType(rawValue: "ca.jameshurst.Magnesium.recheck"),
            handler: handler
        )
    }
}
