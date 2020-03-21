import Deluge
import Foundation
import Keychain
import Preferences
import Transmission

struct Environment {
    let deluge: (URL, String) -> DelugeClient
    let transmission: (URL, String?, String?) -> TransmissionClient
    let preferences: Preferences
    let keychain: Keychain
    let locale: Locale
    let calendar: Calendar
    let fileSystem: FileSystem
    let defaults: Defaults
}

extension Environment {
    static let live: Environment = .init(
        deluge: Deluge.init,
        transmission: Transmission.init,
        preferences: UserDefaultsPreferences(),
        keychain: SystemKeychain(),
        locale: .autoupdatingCurrent,
        calendar: .autoupdatingCurrent,
        fileSystem: .live,
        defaults: .live
    )
}

#if DEBUG
    var Current: Environment = .live // swiftlint:disable:this identifier_name
#else
    var Current: Environment = .live // swiftlint:disable:this identifier_name
#endif
