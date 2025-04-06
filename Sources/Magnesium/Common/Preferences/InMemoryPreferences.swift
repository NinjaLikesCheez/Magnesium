import Combine

/// A preferences implementation that stores values in memory.
public final class InMemoryPreferences: Preferences {
    private let changeSubject = PassthroughSubject<PreferenceChange, Never>()
    private let store: Store

    /// Creates a new in-memory preferences instance.
    public init(store: Store = .init()) {
        self.store = store
    }

    public var changePublisher: AnyPublisher<PreferenceChange, Never> {
        changeSubject.eraseToAnyPublisher()
    }

    public func value<T>(for key: PreferenceKey<T>) -> T {
        store[key]
    }

    public func set<T>(_ value: T, for key: PreferenceKey<T>) {
        store[key] = value
        changeSubject.send(.updated(AnyPreferenceKey(key), value))
    }

    public func containsValue<T>(for key: PreferenceKey<T>) -> Bool {
        store.containsValue(for: key)
    }

    public func removeValue<T>(for key: PreferenceKey<T>) {
        store.removeValue(for: key)
        changeSubject.send(.deleted(AnyPreferenceKey(key)))
    }

    public func reset() {
        store.removeAll()
        changeSubject.send(.reset)
    }
}

public extension InMemoryPreferences {
    /// A container to store values in a dictionary.
    final class Store {
        /// The stored values.
        public var values = [AnyPreferenceKey: Any]()

        /// Creates a new in-memory preferences store.
        public init() {}

        func containsValue<T>(for key: PreferenceKey<T>) -> Bool {
            values.keys.contains(AnyPreferenceKey(key))
        }

        func removeValue<T>(for key: PreferenceKey<T>) {
            values.removeValue(forKey: AnyPreferenceKey(key))
        }

        func removeAll() {
            values.removeAll()
        }

        /// The subscript accessor for stored values.
        subscript<T>(key: PreferenceKey<T>) -> T {
            get { values[AnyPreferenceKey(key)] as? T ?? key.defaultValue }
            set { values[AnyPreferenceKey(key)] = newValue }
        }
    }
}
