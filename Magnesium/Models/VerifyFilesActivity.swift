//
//  VerifyFilesActivity.swift
//  Magnesium
//
//  Created by James Hurst on 2020-02-09.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import UIKit

final class VerifyFilesActivity: BlockActivity {
    init(handler: @escaping () -> Void) {
        super.init(
            title: "Verify Files",
            image: UIImage(systemName: "tray.full"),
            type: UIActivity.ActivityType(rawValue: "ca.jameshurst.Magnesium.verify-files"),
            handler: handler
        )
    }
}
