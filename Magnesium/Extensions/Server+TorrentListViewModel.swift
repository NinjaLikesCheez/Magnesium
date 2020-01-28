//
//  Server+TorrentListViewModel.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-14.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Foundation
import Preferences

extension Server {
    func listViewModel(preferences: Preferences) -> TorrentListViewModel? {
        switch type {
        case .deluge:
            let decoder = JSONDecoder()
            guard let settings = try? decoder.decode(DelugeServerSettings.self, from: data),
                let keychainData = keychainData,
                let keychain = try? decoder.decode(DelugeKeychainData.self, from: keychainData)
            else {
                return nil
            }
            let client = DefaultDelugeClient(
                baseURL: settings.url,
                password: keychain.password
            )
            return DelugeTorrentListViewModel(client: client, preferences: preferences)
        case .transmission:
            let decoder = JSONDecoder()
            guard let settings = try? decoder.decode(TransmissionServerSettings.self, from: data),
                let keychainData = keychainData,
                let keychain = try? decoder.decode(TransmissionKeychainData.self, from: keychainData)
            else {
                return nil
            }
            let client = DefaultTransmissionClient(
                baseURL: settings.url,
                username: settings.username,
                password: keychain.password
            )
            return TransmissionTorrentListViewModel(client: client, preferences: preferences)
        }
    }
}
