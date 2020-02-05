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
    private let preferencesChangedSubject = PassthroughSubject<PreferenceChange, Never>()
    private var storage = [String: Any]()

    var preferencesChanged: AnyPublisher<PreferenceChange, Never> {
        return preferencesChangedSubject.eraseToAnyPublisher()
    }

    func value<T>(for key: PreferenceKey<T>) -> T {
        return storage[key.value] as? T ?? key.defaultValue
    }

    func set<T>(_ value: T, for key: PreferenceKey<T>) {
        storage[key.value] = value
        preferencesChangedSubject.send(.updated(AnyPreferenceKey(key), value))
    }

    func containsValue<T>(for key: PreferenceKey<T>) -> Bool {
        return storage[key.value] != nil
    }

    func removeValue<T>(for key: PreferenceKey<T>) {
        storage.removeValue(forKey: key.value)
        preferencesChangedSubject.send(.deleted(AnyPreferenceKey(key)))
    }

    func reset() {
        storage = [:]
        preferencesChangedSubject.send(.reset)
    }
}
