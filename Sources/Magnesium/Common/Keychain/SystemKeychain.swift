import Combine
import Foundation
import os

/// A keychain implementation that uses the system keychain.
public final class SystemKeychain: Keychain {
    private let changeSubject = PassthroughSubject<KeychainChange, Never>()

    public var changePublisher: AnyPublisher<KeychainChange, Never> {
        changeSubject.eraseToAnyPublisher()
    }

    /// Creates a keychain used to access the system keychain.
    public init() {}

    public func data(for query: KeychainQuery) throws(KeychainError) -> Data? {
        let rawQuery = query.rawQuery(with: [
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnData as String: true,
        ])
        return try get(query: rawQuery)
    }

    public func set(_ data: Data, for query: KeychainQuery) throws(KeychainError) {
        let rawQuery = query.rawQuery(with: [
            kSecValueData as String: data,
        ])
        try delete(query: rawQuery)
        try add(query: rawQuery)
        changeSubject.send(.updated(query, data))
    }

    public func removeData(for query: KeychainQuery) throws(KeychainError) {
        try delete(query: query.rawQuery())
        changeSubject.send(.deleted(query))
    }

    private func get(query: [String: Any]) throws(KeychainError) -> Data? {
        var result: AnyObject?

        let status = withUnsafeMutablePointer(to: &result) {
            SecItemCopyMatching(query as CFDictionary, $0)
        }

        guard status != errSecItemNotFound else {
            return nil
        }

        if status != errSecSuccess {
            os_log("%@: Failed to copy keychain item (%d). Query: %@", #function, status, String(describing: query))
            throw KeychainError.system(status)
        }

        guard let data = result as? Data else {
            os_log("%@: Failed to cast result to data (%d). Query: %@", #function, status, String(describing: query))
            throw KeychainError.unknown
        }

        return data
    }

    private func add(query: [String: Any]) throws(KeychainError) {
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            os_log("%@: Failed to add keychain item (%d). Query: %@", #function, status, String(describing: query))
            throw KeychainError.system(status)
        }
    }

    private func delete(query: [String: Any]) throws(KeychainError) {
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            os_log("%@: Failed to delete keychain item (%d). Query: %@", #function, status, String(describing: query))
            throw KeychainError.system(status)
        }
    }
}
