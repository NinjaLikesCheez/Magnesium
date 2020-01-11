//
//  Server.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-09.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import Foundation

struct Server: Codable, Equatable {
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case data
    }

    fileprivate var id = UUID()
    var name: CurrentValueSubject<String, Never>
    var data: CurrentValueSubject<Data, Never>

    static func == (lhs: Server, rhs: Server) -> Bool {
        return lhs.id == rhs.id && lhs.name === rhs.name && lhs.data === rhs.data
    }

    init(name: String, data: Data) {
        self.name = CurrentValueSubject(name)
        self.data = CurrentValueSubject(data)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = CurrentValueSubject(try container.decode(String.self, forKey: .name))
        data = CurrentValueSubject(try container.decode(Data.self, forKey: .data))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name.value, forKey: .name)
        try container.encode(data.value, forKey: .data)
    }
}

protocol ServerManager {
    func getServers() -> [Server]
    func addOrUpdate(server: Server)
    func reset()
    func clearCache()
}

final class DefaultServerManager: ServerManager {
    static let shared = DefaultServerManager()

    private let userDefaults = UserDefaults.standard
    private var servers: [UUID: Server]?

    private init() {}

    private func getServersMap() -> [UUID: Server] {
        if let servers = servers {
            return servers
        }

        guard let serversData = userDefaults.data(forKey: "servers") else {
            return [:]
        }

        let serversArray = (try? PropertyListDecoder().decode([Server].self, from: serversData)) ?? []
        let servers = serversArray.reduce(into: [UUID: Server]()) { $0[$1.id] = $1 }
        self.servers = servers
        return servers
    }

    func getServers() -> [Server] {
        return Array(getServersMap().values)
    }

    func addOrUpdate(server: Server) {
        var servers = getServersMap()
        servers[server.id] = server
        self.servers = servers

        guard let data = try? PropertyListEncoder().encode(Array(servers.values)) else { return }
        userDefaults.set(data, forKey: "servers")
    }

    func reset() {
        servers = [:]
        userDefaults.removeObject(forKey: "servers")
    }

    func clearCache() {
        servers = nil
    }
}
