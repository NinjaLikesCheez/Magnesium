import Combine
import Foundation

/// A preferences implementation that uses `UserDefaults`.
public class UserDefaultsPreferences: Preferences {
    private let userDefaults: UserDefaults
    private let changeSubject = PassthroughSubject<PreferenceChange, Never>()

    public var changePublisher: AnyPublisher<PreferenceChange, Never> {
        changeSubject.eraseToAnyPublisher()
    }

    /// Creates a new UserDefaults preferences instance with the given UserDefaults.
    /// - Parameter userDefaults: The `UserDefaults` instance to use.
    public init(userDefaults: UserDefaults = UserDefaults.standard) {
        self.userDefaults = userDefaults
    }

    private func isNativeType(_ type: Any.Type) -> Bool {
        switch type {
        case is String.Type, is Bool.Type, is Int.Type, is Float.Type, is Double.Type, is Date.Type:
            return true
        default:
            return false
        }
    }

    private func encode<T>(_ value: T) throws -> Any where T: Codable {
        guard !isNativeType(T.self) else {
            return value
        }

        return try JSONEncoder().encode(value)
    }

    public func value<T>(for key: PreferenceKey<T>) throws -> T {
        if isNativeType(T.self) {
            return userDefaults.value(forKey: key.identifier) as? T ?? key.defaultValue
        } else {
            guard let data = userDefaults.data(forKey: key.identifier) else { return key.defaultValue }
            return try JSONDecoder().decode(T.self, from: data)
        }
    }

    public func set<T>(_ value: T, for key: PreferenceKey<T>) throws {
        userDefaults.set(try encode(value), forKey: key.identifier)
        changeSubject.send(.updated(AnyPreferenceKey(key), value))
    }

    public func containsValue<T>(for key: PreferenceKey<T>) -> Bool {
        userDefaults.value(forKey: key.identifier) != nil
    }

    public func removeValue<T>(for key: PreferenceKey<T>) {
        userDefaults.removeObject(forKey: key.identifier)
        changeSubject.send(.deleted(AnyPreferenceKey(key)))
    }

    public func reset() {
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else { return }
        userDefaults.removePersistentDomain(forName: bundleIdentifier)
        changeSubject.send(.reset)
    }
}
