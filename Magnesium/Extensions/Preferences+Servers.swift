//
//  PreferenceManager+Servers.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-09.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import Foundation
import Preferences

struct Server: Codable, Equatable {
    fileprivate(set) var id = UUID()
    var name: String
    var data: Data
}

private enum Keys {
    static let servers = PreferenceKey<[Server]>("servers")
}

extension Preferences {
    func serverUpdatedPublisher(for server: Server) -> AnyPublisher<Server, Never> {
        return valueUpdatedPublisher(for: Keys.servers)
            .compactMap { servers -> Server? in
                servers?.first(where: { $0.id == server.id })
            }
            .eraseToAnyPublisher()
    }

    func getServers() -> [Server] {
        return (try? value(for: Keys.servers)) ?? []
    }

    func addOrUpdate(server: Server) {
        var servers = getServers()

        if let index = servers.firstIndex(where: { $0.id == server.id }) {
            servers[index] = server
        } else {
            servers.append(server)
        }

        _ = try? set(servers, for: Keys.servers)
    }

    func removeServers() {
        removeValue(for: Keys.servers)
    }
}
