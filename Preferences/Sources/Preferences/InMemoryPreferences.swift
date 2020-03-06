import Combine

/// A `Preferences` implementation that stores values in memory.
public final class InMemoryPreferences: Preferences {
    private let preferencesChangedSubject = PassthroughSubject<PreferenceChange, Never>()
    private var storage = [String: Any]()

    /// Creates an `InMemoryPreferences`.
    public init() {}

    public var preferencesChanged: AnyPublisher<PreferenceChange, Never> {
        return preferencesChangedSubject.eraseToAnyPublisher()
    }

    public func value<T>(for key: PreferenceKey<T>) -> T {
        return storage[key.value] as? T ?? key.defaultValue
    }

    public func set<T>(_ value: T, for key: PreferenceKey<T>) {
        storage[key.value] = value
        preferencesChangedSubject.send(.updated(AnyPreferenceKey(key), value))
    }

    public func containsValue<T>(for key: PreferenceKey<T>) -> Bool {
        return storage[key.value] != nil
    }

    public func removeValue<T>(for key: PreferenceKey<T>) {
        storage.removeValue(forKey: key.value)
        preferencesChangedSubject.send(.deleted(AnyPreferenceKey(key)))
    }

    public func reset() {
        storage = [:]
        preferencesChangedSubject.send(.reset)
    }
}
