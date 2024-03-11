import Deluge
import Foundation
import Keychain
import Preferences
import Transmission

struct Environment {
    var deluge: (URL, String, BasicAuthentication?) -> DelugeClient
    var transmission: (URL, String?, String?) -> TransmissionClient
    var preferences: Preferences
    var keychain: Keychain
    var locale: Locale
    var calendar: Calendar
    var fileSystem: FileSystem
    var defaults: Defaults
}

extension Environment {
    static let live = Environment(
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
    let Current: Environment = .live // swiftlint:disable:this identifier_name
#endif
