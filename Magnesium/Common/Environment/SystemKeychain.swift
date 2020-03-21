import Foundation
import os

/// A keychain implementation that uses the system keychain.
public final class SystemKeychain: Keychain {
    /// Creates a keychain used to access the system keychain.
    public init() {}

    public func fetch(_ key: KeychainKey) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: key.class,
            kSecAttrService as String: key.service,
            kSecAttrAccount as String: key.account,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnData as String: true,
        ]
        return fetch(query: query)
    }

    public func update(_ key: KeychainKey, data: Data) {
        let query: [String: Any] = [
            kSecClass as String: key.class,
            kSecAttrService as String: key.service,
            kSecAttrAccount as String: key.account,
            kSecValueData as String: data,
        ]
        update(query: query)
    }

    public func delete(_ key: KeychainKey) {
        let query: [String: Any] = [
            kSecClass as String: key.class,
            kSecAttrService as String: key.service,
            kSecAttrAccount as String: key.account,
        ]
        delete(query: query)
    }

    public func delete(_ key: KeychainGroupKey) {
        let query: [String: Any] = [
            kSecClass as String: key.class,
            kSecAttrService as String: key.service,
        ]
        delete(query: query)
    }

    private func fetch(query: [String: Any]) -> Data? {
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

    private func update(query: [String: Any]) {
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            os_log("%@: Failed to add keychain item (%d). Query: %@", #function, status, String(describing: query))
            return
        }
    }

    private func delete(query: [String: Any]) {
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess, status == errSecItemNotFound else {
            os_log("%@: Failed to delete keychain item (%d). Query: %@", #function, status, String(describing: query))
            return
        }
    }
}
