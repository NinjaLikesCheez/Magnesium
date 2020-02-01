//
//  PreviewPreferences.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-14.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import Preferences

struct PreviewPreferences: Preferences {
    let preferencesChanged: AnyPublisher<PreferenceChange, Never> = Empty().eraseToAnyPublisher()

    func set<T>(_ value: T, for key: PreferenceKey<T>) {}
    func removeValue<T>(for key: PreferenceKey<T>) {}
    func reset() {}

    func value<T>(for key: PreferenceKey<T>) -> T {
        return key.defaultValue
    }

    func containsValue<T>(for key: PreferenceKey<T>) -> Bool {
        return false
    }
}
