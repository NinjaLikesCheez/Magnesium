//
//  AdvancedSettingsViewModel.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-31.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import Foundation
import os
import Preferences
import ViewModel

enum AdvancedSettingsViewEvent {
    case resetDataSelected
}

struct AdvancedSettingsViewState {}

final class AdvancedSettingsViewModel: ViewModel {
    private let preferences: Preferences
    let state = AdvancedSettingsViewState()

    init(preferences: Preferences) {
        self.preferences = preferences
    }

    func handle(_ event: AdvancedSettingsViewEvent) {
        switch event {
        case .resetDataSelected:
            handleResetDataSelected()
        }
    }

    private func handleResetDataSelected() {
        preferences.reset()
        resetKeychain()
    }

    private func resetKeychain() {
        let keychainQuery: [String: Any] = [kSecClass as String: kSecClassGenericPassword]
        let status = SecItemDelete(keychainQuery as CFDictionary)
        if status != errSecSuccess, status != errSecItemNotFound {
            os_log("%@: Failed to clear keychain with status=%d", #function, status)
        }
    }
}
