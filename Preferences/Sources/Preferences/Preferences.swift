import Combine

/// A type that is able to store preferences.
public protocol Preferences {
    /// A publisher which emits values when a preference is changed.
    var valueUpdated: AnyPublisher<(AnyPreferenceKey, Any?), Never> { get }

    /// Registers a default value for a preference.
    /// - Parameters:
    ///   - value: The default value for the preference.
    ///   - key: The preference key.
    func registerDefault<T>(_ value: T, for key: PreferenceKey<T>) throws

    /// Retrieves the value for a preference.
    /// - Parameter key: The preference key.
    /// - Returns: The preference's value.
    func value<T>(for key: PreferenceKey<T>) throws -> T?

    /// Sets a preference's value.
    /// - Parameters:
    ///   - value: The value to set.
    ///   - key: The preference key.
    func set<T>(_ value: T, for key: PreferenceKey<T>) throws

    /// Checks if the preferences contains a value for a specific preference.
    /// - Parameter key: The preference key.
    /// - Returns: If the preferences contained a value for the specified preference.
    func containsValue<T>(for key: PreferenceKey<T>) -> Bool

    /// Removes a preference's value.
    /// - Parameter key: The preference key.
    func removeValue<T>(for key: PreferenceKey<T>)
}

public extension Preferences {
    /// Returns a publisher that emits values when a preference is changed.
    /// - Parameter key: The preference key to observe.
    func valueUpdatedPublisher<T>(for key: PreferenceKey<T>) -> AnyPublisher<T?, Never> {
        return valueUpdated
            .filter { $0.0.value == key.value }
            .map { $0.1 as? T }
            .eraseToAnyPublisher()
    }

    /// Returns a publisher that emits the current preference value and new values when the preference is
    /// changed.
    /// - Parameter key: The preference key to observe.
    func valuePublisher<T>(for key: PreferenceKey<T>) -> AnyPublisher<T?, Never> {
        return valueUpdatedPublisher(for: key)
            .prepend(try? value(for: key))
            .eraseToAnyPublisher()
    }
}
