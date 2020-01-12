//
//  PresentationStyle.swift
//  Navigator
//
//  Created by James Hurst on 2019-12-19.
//  Copyright © 2019 James Hurst. All rights reserved.
//

import Foundation

/// Styles that can be used for presentations.
public enum PresentationStyle {
    case automatic
    case fullScreen
    case pageSheet
    case formSheet
    case currentContext
    case custom
    case overFullScreen
    case overCurrentContext
    case popover(source: PopoverSource)
    case none
}
