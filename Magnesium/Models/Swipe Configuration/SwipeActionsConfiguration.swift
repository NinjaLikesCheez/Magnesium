//
//  SwipeActionsConfiguration.swift
//  Magnesium
//
//  Created by James Hurst on 2020-02-19.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Foundation

/// A model describing the swipe actions for a cell.
struct SwipeActionsConfiguration {
    /// The swipe actions.
    var actions: [SwipeAction]
    /// Whether a full swipe automatically performs the first action.
    var performsFirstActionWithFullSwipe = true
}
