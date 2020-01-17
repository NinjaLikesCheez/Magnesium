//
//  MockPreferences.swift
//  MagnesiumTests
//
//  Created by James Hurst on 2020-01-17.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import Preferences

final class MockPreferences: Preferences {
    let valueUpdatedSubject = PassthroughSubject<(AnyPreferenceKey, Any?), Never>()
    private var storage = [String: Any]()

    var valueUpdated: AnyPublisher<(AnyPreferenceKey, Any?), Never> {
        return valueUpdatedSubject.eraseToAnyPublisher()
    }

    func registerDefault<T>(_ value: T, for key: PreferenceKey<T>) {
        storage[key.value] = value
    }

    func value<T>(for key: PreferenceKey<T>) throws -> T? {
        return storage[key.value] as? T
    }

    func set<T>(_ value: T, for key: PreferenceKey<T>) {
        storage[key.value] = value
        valueUpdatedSubject.send((AnyPreferenceKey(key.value), value))
    }

    func containsValue<T>(for key: PreferenceKey<T>) -> Bool {
        return storage[key.value] != nil
    }

    func removeValue<T>(for key: PreferenceKey<T>) {
        storage.removeValue(forKey: key.value)
        valueUpdatedSubject.send((AnyPreferenceKey(key.value), nil))
    }
}
