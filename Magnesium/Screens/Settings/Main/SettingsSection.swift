//
//  SettingsSection.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-16.
//  Copyright © 2020 James Hurst. All rights reserved.
//

struct SettingsSection: Equatable {
    let type: SettingsSectionType
    let items: [SettingsItem]
}

enum SettingsSectionType: Hashable {
    case changeServer
    case servers
    case general
    case advancedSettings
}
