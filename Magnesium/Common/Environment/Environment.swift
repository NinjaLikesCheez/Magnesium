import Deluge
import Foundation
import Preferences
import Transmission

struct Environment {
    var deluge: (URL, String) -> DelugeClient = Deluge.init
    var transmission: (URL, String?, String?) -> TransmissionClient = Transmission.init
    var preferences: Preferences = UserDefaultsPreferences()
    var keychain = Keychain()
}

#if DEBUG
    var Current = Environment() // swiftlint:disable:this identifier_name
#else
    let Current = Environment() // swiftlint:disable:this identifier_name
#endif
