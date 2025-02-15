import Combine
import Foundation

/// A keychain implementation that stores values in memory.
public final class InMemoryKeychain: Keychain {
    private let changeSubject = PassthroughSubject<KeychainChange, Never>()
    private let store: Store

    public var changePublisher: AnyPublisher<KeychainChange, Never> {
        changeSubject.eraseToAnyPublisher()
    }

    /// Creates a new in-memory keychain instance.
    public init(store: Store = .init()) {
        self.store = store
    }

    public func data(for query: KeychainQuery) -> Data? {
        store[query]
    }

    public func set(_ data: Data, for query: KeychainQuery) {
        store[query] = data
        changeSubject.send(.updated(query, data))
    }

    public func removeData(for query: KeychainQuery) {
        store.removeValue(for: query)
        changeSubject.send(.deleted(query))
    }
}

public extension InMemoryKeychain {
    /// A container to store values in a dictionary.
    final class Store {
        /// The stored values.
        public var values = [KeychainQuery: Data]()

        /// Creates a new in-memory preferences store.
        public init() {}

        func removeValue(for query: KeychainQuery) {
            values = values.filter { !query.matches(query: $0.key) }
        }

        /// The subscript accessor for stored values.
        subscript(key: KeychainQuery) -> Data? {
            get { values[key] }
            set { values[key] = newValue }
        }
    }
}
