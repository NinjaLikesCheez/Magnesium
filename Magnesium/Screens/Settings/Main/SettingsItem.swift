//
//  SettingsItem.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-16.
//  Copyright © 2020 James Hurst. All rights reserved.
//

enum SettingsItem: Hashable, Equatable {
    case changeServer(String)
    case server(id: AnyHashable, name: String)
    case addServer
    case advancedSettings
}
