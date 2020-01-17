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
    // swiftlint:disable:next type_name
    typealias ID = String
    fileprivate(set) var id: ID = UUID().uuidString
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
    case transmission

    var displayString: String {
        switch self {
        case .deluge:
            return "Deluge"
        case .transmission:
            return "Transmission"
        }
    }
}

extension Preferences {
    private func updateSelectedServerID() {
        guard let server = getSelectedServer() else {
            removeValue(for: PreferenceKeys.selectedServerID)
            return
        }

        _ = try? set(server.id, for: PreferenceKeys.selectedServerID)
    }

    func serverUpdatedPublisher(for server: Server) -> AnyPublisher<Server?, Never> {
        return valueUpdatedPublisher(for: PreferenceKeys.servers)
            .map { servers -> Server? in
                servers?.first { $0.id == server.id }
            }
            .prepend(getServers().first { $0.id == server.id })
            .removeDuplicates()
            .dropFirst()
            .eraseToAnyPublisher()
    }

    func getSelectedServer() -> Server? {
        let servers = getServers()
        guard let selectedServerID = try? value(for: PreferenceKeys.selectedServerID) else { return servers.first }
        return servers.first { $0.id == selectedServerID } ?? servers.first
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
        updateSelectedServerID()
    }

    func remove(server: Server) {
        var servers = getServers()
        servers.removeAll { $0.id == server.id }
        _ = try? set(servers, for: PreferenceKeys.servers)
        updateSelectedServerID()
    }

    func removeServers() {
        removeValue(for: PreferenceKeys.servers)
        removeValue(for: PreferenceKeys.selectedServerID)
    }
}
