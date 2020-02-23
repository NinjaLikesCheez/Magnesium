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
    func listViewModel(preferences: Preferences) -> AnyTorrentListViewModel? {
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
            let implementation = DelugeTorrentListViewModelImplementation(client: client, preferences: preferences)
            let viewModel = StandardTorrentListViewModel(
                implementation: implementation,
                server: self,
                preferences: preferences
             )
            return AnyTorrentListViewModel(viewModel)
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
            let implementation = TransmissionTorrentListViewModelImplementation(
                client: client,
                preferences: preferences
            )
            let viewModel = StandardTorrentListViewModel(
                implementation: implementation,
                server: self,
                preferences: preferences
            )
            return AnyTorrentListViewModel(viewModel)
        }
    }
}
