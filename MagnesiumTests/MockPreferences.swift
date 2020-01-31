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
    private let preferenceChangedSubject = PassthroughSubject<PreferenceChange, Never>()
    private var storage = [String: Any]()

    var preferenceChanged: AnyPublisher<PreferenceChange, Never> {
        return preferenceChangedSubject.eraseToAnyPublisher()
    }

    func value<T>(for key: PreferenceKey<T>) -> T {
        return storage[key.value] as? T ?? key.defaultValue
    }

    func set<T>(_ value: T, for key: PreferenceKey<T>) {
        storage[key.value] = value
        preferenceChangedSubject.send(PreferenceChange(key: AnyPreferenceKey(key.value), type: .updated(value)))
    }

    func containsValue<T>(for key: PreferenceKey<T>) -> Bool {
        return storage[key.value] != nil
    }

    func removeValue<T>(for key: PreferenceKey<T>) {
        storage.removeValue(forKey: key.value)
        preferenceChangedSubject.send(PreferenceChange(key: AnyPreferenceKey(key.value), type: .deleted))
    }
}
