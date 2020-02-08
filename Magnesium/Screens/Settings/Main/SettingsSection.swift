//
//  SettingsSection.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-16.
//  Copyright © 2020 James Hurst. All rights reserved.
//

struct SettingsSection: Equatable {
    enum Types: Hashable {
        case changeServer
        case servers
        case general
        case advancedSettings
    }

    let type: Types
    let items: [SettingsItem]
}
