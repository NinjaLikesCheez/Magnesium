import Foundation
@testable import Magnesium
import Preferences

extension Environment {
    static var mock: Environment { .mock() }

    static func mock(
        deluge: @escaping (URL, String) -> DelugeClient = { _, _ in MockDelugeClient() },
        transmission: @escaping (URL, String?, String?) -> TransmissionClient = { _, _, _ in MockTransmissionClient() },
        preferences: Preferences = InMemoryPreferences()
    ) -> Environment {
        Environment(
            deluge: deluge,
            transmission: transmission,
            preferences: preferences
        )
    }
}
