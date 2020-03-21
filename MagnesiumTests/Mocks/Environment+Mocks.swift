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
        locale: Locale = .init(identifier: "en_US"),
        calendar: Calendar = mockCalendar()
    ) -> Environment {
        Environment(
            deluge: deluge,
            transmission: transmission,
            preferences: preferences,
            keychain: keychain,
            locale: locale,
            calendar: calendar
        )
    }

    static func mockCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = .init(identifier: "en_US")
        return calendar
    }
}
