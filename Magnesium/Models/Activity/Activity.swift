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
    /// The title of the activity.
    var title: String
    /// The image displayed with the activity.
    var image: UIImage?
    /// A unique identifier for the type of action. This is typically in reverse DNS format.
    var type: String
    /// The handler to run when the activity is selected.
    var handler: () -> Void
}
