import Combine
import Foundation
import os
import Preferences

extension Preferences {
    private func keychainQuery(for server: Server) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "servers",
            kSecAttrAccount as String: server.id,
        ]
    }

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
            .prepend(getServers().first { $0.id == server.id })
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
            var query = keychainQuery(for: server)
            query[kSecMatchLimit as String] = kSecMatchLimitOne
            query[kSecReturnData as String] = true
            var result: AnyObject?

            let status = withUnsafeMutablePointer(to: &result) {
                SecItemCopyMatching(query as CFDictionary, $0)
            }

            guard status != errSecItemNotFound else {
                continue
            }

            if status != errSecSuccess {
                os_log("%@: server %@: SecItemCopyMatching -> %d", #function, server.id, status)
                continue
            }

            guard let data = result as? Data else {
                os_log("%@: server %@: unable to cast result to data", #function, server.id, status)
                continue
            }

            server.keychainData = data
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
            var query = keychainQuery(for: server)

            let status = SecItemDelete(query as CFDictionary)
            if status != errSecSuccess, status != errSecItemNotFound {
                os_log("%@: server %@: SecItemDelete -> %d", #function, server.id, status)
            }

            if let data = server.keychainData {
                query[kSecValueData as String] = data
                let status = SecItemAdd(query as CFDictionary, nil)
                if status != errSecSuccess {
                    os_log("%@: server %@: SecItemAdd -> %d", #function, server.id, status)
                }
            }
        }

        self[.servers] = servers
        updateSelectedServerID()
    }

    func remove(server: Server) {
        var servers = getServers()
        servers.removeAll { $0.id == server.id }

        let status = SecItemDelete(keychainQuery(for: server) as CFDictionary)
        if status != errSecSuccess {
            os_log("%@: server %@: SecItemDelete -> %d", #function, server.id, status)
        }

        self[.servers] = servers
        updateSelectedServerID()
    }

    func removeServers() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "servers",
        ]
        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess, status != errSecItemNotFound {
            os_log("%@: SecItemDelete -> %d", #function, status)
        }
        removeValue(for: .servers)
        removeValue(for: .selectedServerID)
    }
}
