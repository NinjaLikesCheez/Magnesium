import Combine
import Preferences

extension Preferences {
    private func updateSelectedServerID() {
        guard let server = getSelectedServer() else {
            removeValue(for: .selectedServerID)
            return
        }

        self[.selectedServerID] = server.id
    }

    func serverUpdatedPublisher(for server: Server) -> AnyPublisher<Server?, Never> {
        preferencesChanged
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
            .prepend(Deferred { Just(self.getServers().first { $0.id == server.id }) })
            .removeDuplicates()
            .dropFirst()
            .eraseToAnyPublisher()
    }

    func getSelectedServer() -> Server? {
        let servers = getServers()
        guard let selectedServerID = self[.selectedServerID] else { return servers.first }
        return servers.first { $0.id == selectedServerID } ?? servers.first
    }

    func getServers() -> [Server] {
        var servers = self[.servers]
        for (index, server) in servers.enumerated() {
            var server = server
            server.keychainData = Current.keychain.fetch(.server(server))
            servers[index] = server
        }

        return servers
    }

    func addOrUpdate(server: Server) {
        var servers = getServers()

        if let index = servers.firstIndex(where: { $0.id == server.id }) {
            servers[index] = server
        } else {
            servers.append(server)
        }

        for server in servers {
            Current.keychain.delete(.server(server))

            if let data = server.keychainData {
                Current.keychain.update(.server(server), data: data)
            }
        }

        self[.servers] = servers
        updateSelectedServerID()
    }

    func remove(server: Server) {
        var servers = getServers()
        servers.removeAll { $0.id == server.id }
        Current.keychain.delete(.server(server))
        self[.servers] = servers
        updateSelectedServerID()
    }

    func removeServers() {
        Current.keychain.delete(.servers)
        removeValue(for: .servers)
        removeValue(for: .selectedServerID)
    }
}
