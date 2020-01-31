//
//  PreviewPreferences.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-14.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import Preferences

#if DEBUG
    struct PreviewPreferences: Preferences {
        let preferenceChanged: AnyPublisher<PreferenceChange, Never> = Empty().eraseToAnyPublisher()

        func set<T>(_ value: T, for key: PreferenceKey<T>) {}
        func removeValue<T>(for key: PreferenceKey<T>) {}

        func value<T>(for key: PreferenceKey<T>) throws -> T {
            return key.defaultValue
        }

        func containsValue<T>(for key: PreferenceKey<T>) -> Bool {
            return false
        }
    }
#endif
