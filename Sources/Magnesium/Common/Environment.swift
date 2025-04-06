import Deluge
import Foundation
// import Keychain
// import Preferences
import QBittorrent

// import Transmission

struct AppEnvironment {
	var deluge: (URL, String, BasicAuthentication?) -> Deluge
	// var transmission: (URL, String?, String?) -> TransmissionClient
	var qbittorrent: (URL, String, String, BasicAuthentication?) -> QBittorrent
	var preferences: Preferences
	var keychain: Keychain
	var locale: Locale
	var calendar: Calendar
	// var fileSystem: FileSystem
	// var defaults: Defaults
}

extension AppEnvironment {
	static let live = AppEnvironment(
		deluge: Deluge.init,
		// transmission: Transmission.init,
		qbittorrent: QBittorrent.init,
		preferences: UserDefaultsPreferences(),
		keychain: SystemKeychain(),
		locale: .autoupdatingCurrent,
		calendar: .autoupdatingCurrent
			// fileSystem: .live,
			// defaults: .live
	)
}

#if DEBUG
	var Current: AppEnvironment = .live  // swiftlint:disable:this identifier_name
#else
	let Current: AppEnvironment = .live  // swiftlint:disable:this identifier_name
#endif
