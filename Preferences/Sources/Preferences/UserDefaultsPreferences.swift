import Combine
import Foundation
import os

/// A `Preferences` implementation that uses `UserDefaults`.
public final class UserDefaultsPreferences: Preferences {
    private let userDefaults: UserDefaults
    private let valueUpdatedSubject = PassthroughSubject<PreferenceChange, Never>()

    public var preferenceChanged: AnyPublisher<PreferenceChange, Never> {
        return valueUpdatedSubject.eraseToAnyPublisher()
    }

    /// Creates a new instance with the given `UserDefaults`.
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

        return try PropertyListEncoder().encode(value)
    }

    public func value<T>(for key: PreferenceKey<T>) -> T {
        if isNativeType(T.self) {
            return userDefaults.value(forKey: key.value) as? T ?? key.defaultValue
        } else {
            do {
                guard let data = userDefaults.data(forKey: key.value) else { return key.defaultValue }
                return try PropertyListDecoder().decode(T.self, from: data)
            } catch {
                os_log("[UserDefaultsPreferences] Failed to decode value: %@", String(describing: error))
                return key.defaultValue
            }
        }
    }

    public func set<T>(_ value: T, for key: PreferenceKey<T>) {
        do {
            userDefaults.set(try encode(value), forKey: key.value)
            valueUpdatedSubject.send(PreferenceChange(key: AnyPreferenceKey(key.value), type: .updated(value)))
        } catch {
            os_log("[UserDefaultsPreferences] Failed to encode value: %@", String(describing: error))
        }
    }

    public func containsValue<T>(for key: PreferenceKey<T>) -> Bool {
        return userDefaults.value(forKey: key.value) != nil
    }

    public func removeValue<T>(for key: PreferenceKey<T>) {
        userDefaults.removeObject(forKey: key.value)
        valueUpdatedSubject.send(PreferenceChange(key: AnyPreferenceKey(key.value), type: .deleted))
    }
}
