//
//  SettingsSection.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-16.
//  Copyright © 2020 James Hurst. All rights reserved.
//

struct SettingsSection: Equatable {
    enum SectionType: Hashable {
        case changeServer
        case servers
        case general
    }

    let type: SectionType
    let items: [SettingsItem]
}
