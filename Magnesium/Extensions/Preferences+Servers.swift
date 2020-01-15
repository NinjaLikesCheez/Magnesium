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
    var type: ServerType
    var data: Data

    init(name: String, type: ServerType, data: Data) {
        self.name = name
        self.type = type
        self.data = data
    }
}

enum ServerType: String, Codable {
    case deluge
}

extension Preferences {
    func serverUpdatedPublisher(for server: Server) -> AnyPublisher<Server, Never> {
        return valueUpdatedPublisher(for: PreferenceKeys.servers)
            .compactMap { servers -> Server? in
                servers?.first(where: { $0.id == server.id })
            }
            .eraseToAnyPublisher()
    }

    func getServers() -> [Server] {
        return (try? value(for: PreferenceKeys.servers)) ?? []
    }

    func addOrUpdate(server: Server) {
        var servers = getServers()

        if let index = servers.firstIndex(where: { $0.id == server.id }) {
            servers[index] = server
        } else {
            servers.append(server)
        }

        _ = try? set(servers, for: PreferenceKeys.servers)
    }

    func remove(server: Server) {
        var servers = getServers()
        servers.removeAll { $0.id == server.id }
        _ = try? set(servers, for: PreferenceKeys.servers)
    }

    func removeServers() {
        removeValue(for: PreferenceKeys.servers)
    }
}
