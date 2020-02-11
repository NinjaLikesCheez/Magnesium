//
//  SetLabelActivity.swift
//  Magnesium
//
//  Created by James Hurst on 2020-02-09.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import UIKit

final class SetLabelActivity: BlockActivity {
    init(handler: @escaping () -> Void) {
        super.init(
            title: "Set Label",
            image: UIImage(systemName: "tag"),
            type: UIActivity.ActivityType(rawValue: "ca.jameshurst.Magnesium.set-label"),
            handler: handler
        )
    }
}
