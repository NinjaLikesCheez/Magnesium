import Combine
import Preferences

extension Preferences {
    private func updateSelectedServerID() throws {
        guard let server = try getSelectedServer() else {
            removeValue(for: .selectedServerID)
            return
        }

        self[.selectedServerID] = server.id
    }

    func serverUpdatedPublisher(for server: Server) -> AnyPublisher<Server?, Never> {
        changePublisher
            .filter { $0.isRelevant(to: .servers) }
            .map { change -> Server? in
                switch change {
                case let .updated(_, value):
                    let servers = value as? [Server]
                    return servers?.first { $0.id == server.id }
                case .deleted:
                    return nil
                case .reset:
                    return nil
                }
            }
            .prepend(Deferred { Just(try? self.getServers().first { $0.id == server.id }) })
            .removeDuplicates()
            .dropFirst()
            .eraseToAnyPublisher()
    }

    func getSelectedServer() throws -> Server? {
        let servers = try getServers()
        guard let selectedServerID = self[.selectedServerID] else { return servers.first }
        return servers.first { $0.id == selectedServerID } ?? servers.first
    }

    func getServers() throws -> [Server] {
        var servers = self[.servers]
        for (index, server) in servers.enumerated() {
            var server = server
            server.keychainData = try Current.keychain.data(for: .server(server))
            servers[index] = server
        }

        return servers
    }

    func addOrUpdate(server: Server) throws {
        var servers = try getServers()

        if let index = servers.firstIndex(where: { $0.id == server.id }) {
            servers[index] = server
        } else {
            servers.append(server)
        }

        for server in servers {
            try Current.keychain.removeData(for: .server(server))

            if let data = server.keychainData {
                try Current.keychain.set(data, for: .server(server))
            }
        }

        self[.servers] = servers
        try updateSelectedServerID()
    }

    func remove(server: Server) throws {
        var servers = try getServers()
        servers.removeAll { $0.id == server.id }
        try Current.keychain.removeData(for: .server(server))
        self[.servers] = servers
        try updateSelectedServerID()
    }

    func removeServers() throws {
        try Current.keychain.removeData(for: .servers)
        removeValue(for: .servers)
        removeValue(for: .selectedServerID)
    }
}
