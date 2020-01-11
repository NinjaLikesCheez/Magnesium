//
//  PreferenceManager.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-11.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import Foundation

struct PreferenceKey<T: Codable> {
    let value: String

    public init(_ value: String) {
        self.value = value
    }
}

struct AnyPreferenceKey {
    let value: String

    public init(_ value: String) {
        self.value = value
    }
}

protocol PreferenceManager {
    var valueUpdated: AnyPublisher<(AnyPreferenceKey, Any), Never> { get }

    func value<T>(for key: PreferenceKey<T>) -> T?
    func set<T>(_ value: T, for key: PreferenceKey<T>)
    func containsValue<T>(for key: PreferenceKey<T>) -> Bool
    func removeValue<T>(for key: PreferenceKey<T>)
}

final class DefaultPreferenceManager: PreferenceManager {
    private let userDefaults: UserDefaults
    private let valueUpdatedSubject = PassthroughSubject<(AnyPreferenceKey, Any), Never>()

    var valueUpdated: AnyPublisher<(AnyPreferenceKey, Any), Never> {
        return valueUpdatedSubject.eraseToAnyPublisher()
    }

    init(userDefaults: UserDefaults = UserDefaults.standard) {
        self.userDefaults = userDefaults
    }

    private func isNativeType<T>(_ type: T.Type) -> Bool {
        switch type {
        case is String.Type, is Bool.Type, is Int.Type, is Float.Type, is Double.Type, is Date.Type:
            return true
        default:
            return false
        }
    }

    func value<T>(for key: PreferenceKey<T>) -> T? {
        if isNativeType(T.self) {
            return userDefaults.value(forKey: key.value) as? T
        } else {
            guard let data = userDefaults.data(forKey: key.value) else { return nil }
            return try? PropertyListDecoder().decode(T.self, from: data)
        }
    }

    func set<T>(_ value: T, for key: PreferenceKey<T>) {
        if isNativeType(T.self) {
            userDefaults.setValue(value, forKey: key.value)
        } else {
            guard let data = try? PropertyListEncoder().encode(value) else { return }
            userDefaults.set(data, forKey: key.value)
        }

        valueUpdatedSubject.send((AnyPreferenceKey(key.value), value))
    }

    func containsValue<T>(for key: PreferenceKey<T>) -> Bool {
        return userDefaults.value(forKey: key.value) != nil
    }

    func removeValue<T>(for key: PreferenceKey<T>) {
        userDefaults.removeObject(forKey: key.value)
    }
}
