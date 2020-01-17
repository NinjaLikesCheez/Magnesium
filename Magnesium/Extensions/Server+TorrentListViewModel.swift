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
    func listViewModel(coordinator: TorrentListCoordinator, preferences: Preferences) -> TorrentListViewModel? {
        switch type {
        case .deluge:
            guard let settings = try? JSONDecoder().decode(DelugeServerSettings.self, from: data) else {
                return nil
            }
            let client = DefaultDelugeClient(
                baseURL: settings.url,
                password: settings.password
            )
            return DelugeTorrentListViewModel(coordinator: coordinator, client: client, preferences: preferences)
        case .transmission:
            guard let settings = try? JSONDecoder().decode(TransmissionServerSettings.self, from: data) else {
                return nil
            }
            let client = TransmissionClient(
                baseURL: settings.url,
                authentication: settings.authentication.map {
                    TransmissionClient.Authentication(username: $0.username, password: $0.password)
                }
            )
            return TransmissionTorrentListViewModel(coordinator: coordinator, client: client, preferences: preferences)
        }
    }
}
