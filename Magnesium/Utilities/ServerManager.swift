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
    fileprivate(set) var id = UUID()
    var name: String
    var data: Data
}

protocol ServerManager {
    var serverUpdated: AnyPublisher<Server, Never> { get }

    func getServers() -> [Server]
    func addOrUpdate(server: Server)
    func reset()
}

final class DefaultServerManager: ServerManager {
    private let userDefaults: UserDefaults
    private let serverUpdatedSubject = PassthroughSubject<Server, Never>()

    var serverUpdated: AnyPublisher<Server, Never> {
        return serverUpdatedSubject.eraseToAnyPublisher()
    }

    init(userDefaults: UserDefaults = UserDefaults.standard) {
        self.userDefaults = userDefaults
    }

    func getServers() -> [Server] {
        guard let data = userDefaults.data(forKey: "servers") else { return [] }
        return (try? PropertyListDecoder().decode([Server].self, from: data)) ?? []
    }

    func addOrUpdate(server: Server) {
        var servers = getServers()

        if let index = servers.firstIndex(where: { $0.id == server.id }) {
            servers[index] = server
        } else {
            servers.append(server)
        }

        guard let data = try? PropertyListEncoder().encode(servers) else { return }
        userDefaults.set(data, forKey: "servers")

        serverUpdatedSubject.send(server)
    }

    func reset() {
        userDefaults.removeObject(forKey: "servers")
    }
}
