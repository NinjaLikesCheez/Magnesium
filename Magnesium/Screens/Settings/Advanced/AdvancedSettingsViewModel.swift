//
//  AdvancedSettingsViewModel.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-31.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Foundation
import os
import Preferences
import ViewModel

enum AdvancedSettingsViewEvent {
    case clearDocumentsSelected
    case clearTempDirectorySelected
    case clearCacheSelected
    case clearLaunchScreenCacheSelected
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
        case .clearDocumentsSelected:
            handleClearDocumentsSelected()
        case .clearTempDirectorySelected:
            handleClearTempDirectorySelected()
        case .clearCacheSelected:
            handleClearCacheSelected()
        case .clearLaunchScreenCacheSelected:
            handleClearLaunchScreenCacheSelected()
        case .resetDataSelected:
            handleResetDataSelected()
        }
    }

    private func handleClearDocumentsSelected() {
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }

        let contents: [URL]
        do {
            contents = try FileManager.default.contentsOfDirectory(
                at: documentsURL,
                includingPropertiesForKeys: nil,
                options: []
            )
        } catch {
            os_log("%@: Failed to read Documents directory: %@", #function, String(describing: error))
            return
        }

        for url in contents {
            do {
                try FileManager.default.removeItem(at: url)
            } catch {
                os_log("%@: Failed to remove Documents item: %@", #function, String(describing: error))
            }
        }
    }

    private func handleClearTempDirectorySelected() {
        let tempURL = FileManager.default.temporaryDirectory
        let contents: [URL]
        do {
            contents = try FileManager.default.contentsOfDirectory(
                at: tempURL,
                includingPropertiesForKeys: nil,
                options: []
            )
        } catch {
            os_log("%@: Failed to read temp directory: %@", #function, String(describing: error))
            return
        }

        for url in contents {
            do {
                try FileManager.default.removeItem(at: url)
            } catch {
                os_log("%@: Failed to remove temp item: %@", #function, String(describing: error))
            }
        }
    }

    private func handleClearCacheSelected() {
        guard let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            return
        }

        let contents: [URL]
        do {
            contents = try FileManager.default.contentsOfDirectory(
                at: cacheURL,
                includingPropertiesForKeys: nil,
                options: []
            )
        } catch {
            os_log("%@: Failed to read Caches directory: %@", #function, String(describing: error))
            return
        }

        for url in contents {
            do {
                try FileManager.default.removeItem(at: url)
            } catch {
                os_log("%@: Failed to remove Caches item: %@", #function, String(describing: error))
            }
        }
    }

    private func handleClearLaunchScreenCacheSelected() {
        guard let libraryURL = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first else {
            return
        }

        let contents: [URL]
        do {
            contents = try FileManager.default.contentsOfDirectory(
                at: libraryURL.appendingPathComponent("SplashBoard"),
                includingPropertiesForKeys: nil,
                options: []
            )
        } catch {
            os_log("%@: Failed to read SplashBoard directory: %@", #function, String(describing: error))
            return
        }

        for url in contents {
            do {
                try FileManager.default.removeItem(at: url)
            } catch {
                os_log("%@: Failed to remove SplashBoard item: %@", #function, String(describing: error))
            }
        }
    }

    private func handleResetDataSelected() {
        preferences.reset()
        resetKeychain()
        handleClearDocumentsSelected()
        handleClearTempDirectorySelected()
        handleClearCacheSelected()
        handleClearLaunchScreenCacheSelected()
    }

    private func resetKeychain() {
        let keychainQuery: [String: Any] = [kSecClass as String: kSecClassGenericPassword]
        let status = SecItemDelete(keychainQuery as CFDictionary)
        if status != errSecSuccess, status != errSecItemNotFound {
            os_log("%@: Failed to clear keychain with status=%d", #function, status)
        }
    }
}
