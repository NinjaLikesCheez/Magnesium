//
//  ServerSettingsViewEvent.swift
//  Magnesium
//
//  Created by James Hurst on 2020-03-05.
//  Copyright © 2020 James Hurst. All rights reserved.
//

enum ServerSettingsViewEvent {
    case saveSelected
    case deleteSelected(source: PopoverSource)
    case cancelSelected
}
