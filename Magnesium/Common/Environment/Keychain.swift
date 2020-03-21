import Foundation

/// A type that is able to store data in the keychain.
public protocol Keychain {
    /// Retrieves the data for the given key.
    /// - Parameter key: A key uniquely identifying the keychain item.
    func fetch(_ key: KeychainKey) -> Data?

    /// Sets the data for the given key.
    /// - Parameters:
    ///   - key: A key uniquely identifying the keychain item.
    ///   - data: The data to set for the given key.
    func update(_ key: KeychainKey, data: Data)

    /// Deletes the data for the given key.
    /// - Parameter key: A key uniquely identifying the keychain item.
    func delete(_ key: KeychainKey)

    /// Deletes all data for the given service.
    /// - Parameter key: A key uniquely identifying the keychain group.
    func delete(_ key: KeychainGroupKey)
}

/// A key that uniquely identifies a keychain item.
public struct KeychainKey {
    /// The class of the keychain item. This refers to the key `kSecClass`.
    let `class`: String
    /// The service of the keychain item. This refers to the key `kSecAttrService`.
    let service: String
    /// The account of the keychain item. This refers to the key `kSecAttrAccount`.
    let account: String
}

/// A key that uniquely identifies a keychain group.
public struct KeychainGroupKey {
    /// The class of the keychain items. This refers to the key `kSecClass`.
    let `class`: String
    /// The service of the keychain items. This refers to the key `kSecAttrService`.
    let service: String
}
