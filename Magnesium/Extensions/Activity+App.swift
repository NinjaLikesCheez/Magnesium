//
//  Activity+App.swift
//  Magnesium
//
//  Created by James Hurst on 2020-02-10.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import UIKit

extension Activity {
    static func setLabel(handler: @escaping () -> Void) -> Activity {
        return Activity(
            title: NSLocalizedString("action_set_label", comment: "Set Label"),
            image: UIImage(systemName: "tag"),
            type: "ca.jameshurst.Magnesium.set-label",
            handler: handler
        )
    }

    static func verifyFiles(handler: @escaping () -> Void) -> Activity {
        return Activity(
            title: NSLocalizedString("action_verify_files", comment: "Verify Files"),
            image: UIImage(systemName: "tray.full"),
            type: "ca.jameshurst.Magnesium.verify-files",
            handler: handler
        )
    }

    static func updateTrackers(handler: @escaping () -> Void) -> Activity {
        return Activity(
            title: NSLocalizedString("action_update_trackers", comment: "Update Trackers"),
            image: UIImage(systemName: "arrow.clockwise"),
            type: "ca.jameshurst.Magnesium.update-trackers",
            handler: handler
        )
    }
}
