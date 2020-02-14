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
            title: L10n.setLabel,
            image: UIImage(systemName: "tag"),
            type: "ca.jameshurst.Magnesium.set-label",
            handler: handler
        )
    }

    static func verifyFiles(handler: @escaping () -> Void) -> Activity {
        return Activity(
            title: L10n.verifyFiles,
            image: UIImage(systemName: "tray.full"),
            type: "ca.jameshurst.Magnesium.verify-files",
            handler: handler
        )
    }

    static func updateTrackers(handler: @escaping () -> Void) -> Activity {
        return Activity(
            title: L10n.updateTrackers,
            image: UIImage(systemName: "arrow.clockwise"),
            type: "ca.jameshurst.Magnesium.update-trackers",
            handler: handler
        )
    }
}
