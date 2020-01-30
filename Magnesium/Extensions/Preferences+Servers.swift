//
//  PreferenceManager+Servers.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-09.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import Foundation
import os
import Preferences

struct Server: Codable, Equatable {
    // swiftlint:disable:next type_name
    typealias ID = String
    fileprivate(set) var id: ID = UUID().uuidString
    var name: String
    var type: ServerType
    var data: Data
    var keychainData: Data?

    enum CodingKeys: CodingKey {
        case id
        case name
        case type
        case data
    }

    init(name: String, type: ServerType, data: Data, keychainData: Data?) {
        self.name = name
        self.type = type
        self.data = data
        self.keychainData = keychainData
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
    private func keychainQuery(for server: Server) -> [String: Any] {
        return [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "servers",
            kSecAttrAccount as String: server.id,
        ]
    }

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
        guard var servers = try? value(for: PreferenceKeys.servers) else {
            return []
        }

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

        _ = try? set(servers, for: PreferenceKeys.servers)
        updateSelectedServerID()
    }

    func remove(server: Server) {
        var servers = getServers()
        servers.removeAll { $0.id == server.id }

        let status = SecItemDelete(keychainQuery(for: server) as CFDictionary)
        if status != errSecSuccess {
            os_log("%@: server %@: SecItemDelete -> %d", #function, server.id, status)
        }

        _ = try? set(servers, for: PreferenceKeys.servers)
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
        removeValue(for: PreferenceKeys.servers)
        removeValue(for: PreferenceKeys.selectedServerID)
    }
}
