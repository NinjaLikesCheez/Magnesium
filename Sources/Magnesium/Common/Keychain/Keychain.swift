import Combine
import Foundation

/// A type that is able to store data in the keychain.
public protocol Keychain {
    /// A publisher that emits values when the keychain is modified.
    var changePublisher: AnyPublisher<KeychainChange, Never> { get }

    /// Retrieves the data for a keychain item.
    /// - Parameter query: The keychain query identifying the item.
    func data(for query: KeychainQuery) throws -> Data?

    /// Sets data for a keychain item.
    /// - Parameters:
    ///   - data: The data for the keychain item.
    ///   - query: The keychain query identifying the item.
    func set(_ data: Data, for query: KeychainQuery) throws

    /// Removes keychain data.
    /// - Parameter query: The keychain query.
    func removeData(for query: KeychainQuery) throws
}

public extension Keychain {
    /// Returns a publisher that emits newly set data for keychain items matching the given query.
    /// - Parameter query: The keychain query.
    func updatePublisher(for query: KeychainQuery) -> AnyPublisher<Data?, Never> {
        changePublisher
            .filter { $0.matches(query: query) }
            .map {
                switch $0 {
                case let .updated(_, data):
                    return data
                case .deleted:
                    return nil
                }
            }
            .eraseToAnyPublisher()
    }

    /// Returns a publisher that emits the current data and newly set data for the keychain item matching the given
    /// query.
    /// - Parameter query: The keychain query.
    func valuePublisher(for query: KeychainQuery) -> AnyPublisher<Data?, Never> {
        updatePublisher(for: query)
            .prepend(Deferred { Just(try? self.data(for: query)) })
            .eraseToAnyPublisher()
    }
}
