//
//  ServerSettingsEvent.swift
//  Magnesium
//
//  Created by James Hurst on 2020-03-05.
//  Copyright © 2020 James Hurst. All rights reserved.
//

enum ServerSettingsEvent {
    case complete
    case alert(Alert, source: PopoverSource?)
}
