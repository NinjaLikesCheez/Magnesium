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

    init(_ value: String) {
        self.value = value
    }
}

struct AnyPreferenceKey {
    let value: String

    fileprivate init(_ value: String) {
        self.value = value
    }
}

protocol PreferenceManager {
    var valueUpdated: AnyPublisher<(AnyPreferenceKey, Any?), Never> { get }

    func registerDefault<T>(_ value: T, for key: PreferenceKey<T>) throws
    func value<T>(for key: PreferenceKey<T>) throws -> T?
    func set<T>(_ value: T, for key: PreferenceKey<T>) throws
    func containsValue<T>(for key: PreferenceKey<T>) -> Bool
    func removeValue<T>(for key: PreferenceKey<T>)
}

extension PreferenceManager {
    func valueUpdatedPublisher<T>(for key: PreferenceKey<T>) -> AnyPublisher<T?, Never> {
        return valueUpdated
            .compactMap { args in
                let (updatedKey, updatedValue) = args
                guard updatedKey.value == key.value else { return nil }
                return updatedValue as? T
            }
            .eraseToAnyPublisher()
    }
}

final class DefaultPreferenceManager: PreferenceManager {
    private let userDefaults: UserDefaults
    private let valueUpdatedSubject = PassthroughSubject<(AnyPreferenceKey, Any?), Never>()

    var valueUpdated: AnyPublisher<(AnyPreferenceKey, Any?), Never> {
        return valueUpdatedSubject.eraseToAnyPublisher()
    }

    init(userDefaults: UserDefaults = UserDefaults.standard) {
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

    func registerDefault<T>(_ value: T, for key: PreferenceKey<T>) throws {
        userDefaults.register(defaults: [key.value: try encode(value)])
    }

    func value<T>(for key: PreferenceKey<T>) throws -> T? {
        if isNativeType(T.self) {
            return userDefaults.value(forKey: key.value) as? T
        } else {
            guard let data = userDefaults.data(forKey: key.value) else { return nil }
            return try PropertyListDecoder().decode(T.self, from: data)
        }
    }

    func set<T>(_ value: T, for key: PreferenceKey<T>) throws {
        userDefaults.set(try encode(value), forKey: key.value)
        valueUpdatedSubject.send((AnyPreferenceKey(key.value), value))
    }

    func containsValue<T>(for key: PreferenceKey<T>) -> Bool {
        return userDefaults.value(forKey: key.value) != nil
    }

    func removeValue<T>(for key: PreferenceKey<T>) {
        userDefaults.removeObject(forKey: key.value)
        valueUpdatedSubject.send((AnyPreferenceKey(key.value), nil))
    }
}
