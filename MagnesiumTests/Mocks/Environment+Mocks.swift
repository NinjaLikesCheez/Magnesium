import Foundation
import Keychain
@testable import Magnesium
import Preferences

extension Environment {
    static var mock: Environment { .mock() }

    static func mock(
        deluge: @escaping (URL, String) -> DelugeClient = { _, _ in MockDelugeClient() },
        transmission: @escaping (URL, String?, String?) -> TransmissionClient = { _, _, _ in MockTransmissionClient() },
        preferences: Preferences = InMemoryPreferences(),
        keychain: Keychain = InMemoryKeychain(),
        locale: Locale = .mock,
        calendar: Calendar = .mock,
        fileSystem: FileSystem = .mock
    ) -> Environment {
        Environment(
            deluge: deluge,
            transmission: transmission,
            preferences: preferences,
            keychain: keychain,
            locale: locale,
            calendar: calendar,
            fileSystem: fileSystem
        )
    }
}

extension Locale {
    static var mock: Locale {
        .init(identifier: "en_US")
    }
}

extension Calendar {
    static var mock: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = .mock
        return calendar
    }
}

extension FileSystem {
    static var mock: FileSystem {
        .init(
            isReadable: { _ in true },
            startAccessingSecurityScopedResource: { _ in true },
            stopAccessingSecurityScopedResource: { _ in }
        )
    }
}
