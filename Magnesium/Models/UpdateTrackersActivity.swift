//
//  UpdateTrackersActivity.swift
//  Magnesium
//
//  Created by James Hurst on 2020-02-10.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import UIKit

final class UpdateTrackersActivity: BlockActivity {
    init(handler: @escaping () -> Void) {
        super.init(
            title: "Update Trackers",
            image: UIImage(systemName: "arrow.clockwise"),
            type: UIActivity.ActivityType(rawValue: "ca.jameshurst.Magnesium.update-trackers"),
            handler: handler
        )
    }
}
