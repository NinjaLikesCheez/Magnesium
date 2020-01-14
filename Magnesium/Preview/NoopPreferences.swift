//
//  NoopPreferences.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-14.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import Preferences

#if DEBUG
    struct NoopPreferences: Preferences {
        var valueUpdated: AnyPublisher<(AnyPreferenceKey, Any?), Never> {
            return Empty().eraseToAnyPublisher()
        }

        func registerDefault<T>(_ value: T, for key: PreferenceKey<T>) {}
        func set<T>(_ value: T, for key: PreferenceKey<T>) {}
        func removeValue<T>(for key: PreferenceKey<T>) {}

        func value<T>(for key: PreferenceKey<T>) throws -> T? {
            return nil
        }

        func containsValue<T>(for key: PreferenceKey<T>) -> Bool {
            return false
        }
    }
#endif
