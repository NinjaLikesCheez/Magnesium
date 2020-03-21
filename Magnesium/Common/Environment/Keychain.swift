import Foundation
import os

struct Keychain {
    var fetchServerData: (Server) -> Data? = fetchKeychainData(for:)
    var updateServerData: (Server) -> Void = updateKeychainData(for:)
    var deleteServerData: (Server) -> Void = deleteKeychainData(for:)
    var deleteAllServerData: () -> Void = deleteKeychainDataForAllServers
}

private func keychainQuery(for server: Server) -> [String: Any] {
    [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: "servers",
        kSecAttrAccount as String: server.id,
    ]
}

private func fetchKeychainData(for server: Server) -> Data? {
    var query = keychainQuery(for: server)
    query[kSecMatchLimit as String] = kSecMatchLimitOne
    query[kSecReturnData as String] = true
    return getKeychainValue(query: query)
}

private func updateKeychainData(for server: Server) {
    guard let data = server.keychainData else { return }
    var query = keychainQuery(for: server)
    query[kSecValueData as String] = data
    setKeychainValue(query: query)
}

private func deleteKeychainData(for server: Server) {
    deleteKeychainValue(query: keychainQuery(for: server))
}

private func deleteKeychainDataForAllServers() {
    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: "servers",
    ]
    deleteKeychainValue(query: query)
}

private func getKeychainValue(query: [String: Any]) -> Data? {
    var result: AnyObject?

    let status = withUnsafeMutablePointer(to: &result) {
        SecItemCopyMatching(query as CFDictionary, $0)
    }

    guard status != errSecItemNotFound else {
        return nil
    }

    if status != errSecSuccess {
        os_log("%@: Failed to copy keychain item (%d). Query: %d", #function, status, String(describing: query))
        return nil
    }

    guard let data = result as? Data else {
        os_log("%@: Failed to cast result to data (%d). Query: %@", #function, status, String(describing: query))
        return nil
    }

    return data
}

private func setKeychainValue(query: [String: Any]) {
    let status = SecItemAdd(query as CFDictionary, nil)
    guard status == errSecSuccess else {
        os_log("%@: Failed to add keychain item (%d). Query: %@", #function, status, String(describing: query))
        return
    }
}

private func deleteKeychainValue(query: [String: Any]) {
    let status = SecItemDelete(query as CFDictionary)
    guard status == errSecSuccess, status == errSecItemNotFound else {
        os_log("%@: Failed to delete keychain item (%d). Query: %@", #function, status, String(describing: query))
        return
    }
}
