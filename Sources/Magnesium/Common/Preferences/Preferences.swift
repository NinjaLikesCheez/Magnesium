import Combine

/// A type that is able to store preferences.
public protocol Preferences {
    /// A publisher that emits values when the preferences are modified.
    var changePublisher: AnyPublisher<PreferenceChange, Never> { get }

    /// Retrieves the value for the given key.
    /// - Parameter key: A key uniquely identifying the preference.
    /// - Returns: The preference value or the default value if none exists.
    func value<T>(for key: PreferenceKey<T>) throws -> T

    /// Sets the value for the given key.
    /// - Parameters:
    ///   - value: The new value for the preference.
    ///   - key: A key uniquely identifying the preference.
    func set<T>(_ value: T, for key: PreferenceKey<T>) throws

    /// Checks whether the preferences contains a value the given key.
    /// - Parameter key: A key uniquely identifying the preference.
    /// - Returns: Whether the preferences contained a value for the given key.
    func containsValue<T>(for key: PreferenceKey<T>) -> Bool

    /// Removes the value for the given key.
    /// - Parameter key: A key uniquely identifying the preference.
    func removeValue<T>(for key: PreferenceKey<T>)

    /// Removes all preferences.
    func reset()
}

public extension Preferences {
    /// The subscript accessor for preferences. Any thrown errors will be discarded.
    subscript<T>(key: PreferenceKey<T>) -> T {
        get {
            (try? value(for: key)) ?? key.defaultValue
        }
        nonmutating set {
            try? set(newValue, for: key)
        }
    }
}

public extension Preferences {
    /// Returns a publisher that emits new values when the preference is updated.
    /// - Parameter key: A key uniquely identifying the preference the observe.
    func updatePublisher<T>(for key: PreferenceKey<T>) -> AnyPublisher<T, Never> {
        changePublisher
            .filter { $0.isRelevant(to: key) }
            .map {
                switch $0 {
                case let .updated(_, value):
                    return value as? T ?? key.defaultValue
                case .deleted:
                    return key.defaultValue
                case .reset:
                    return key.defaultValue
                }
            }
            .eraseToAnyPublisher()
    }

    /// Returns a publisher that emits the current preference value and new values when the preference is updated.
    /// - Parameter key: A key uniquely identifying the preference the observe.
    func valuePublisher<T>(for key: PreferenceKey<T>) -> AnyPublisher<T, Never> {
        updatePublisher(for: key)
            .prepend(Deferred { Just((try? self.value(for: key)) ?? key.defaultValue) })
            .eraseToAnyPublisher()
    }
}
