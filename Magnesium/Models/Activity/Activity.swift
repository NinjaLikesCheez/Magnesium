//
//  Activity.swift
//  Magnesium
//
//  Created by James Hurst on 2020-02-10.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import UIKit

/// A model describing an activity.
struct Activity {
    /// The activity title.
    var title: String
    /// The activity image.
    var image: UIImage?
    /// The activity type identifier. This is typically in reverse DNS format.
    var type: String
    /// The handler to run when the activity is selected.
    var handler: () -> Void
}
