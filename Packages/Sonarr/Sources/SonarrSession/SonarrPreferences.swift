import Common
import Foundation
import ObservableDefaults
import Security
import SonarrCore

/// Persisted Sonarr settings.
///
/// Sonarr only ever talks to a single instance, so unlike `TorrentPreferences` there's no
/// `servers` array/`selectedServerID` pair to reconcile — just one optional `server`.
@ObservableDefaults
@MainActor
public final class SonarrPreferences {
	public var server: SonarrServer?

	@Ignore
	private var keychain: Keychain!

	public convenience init(
		userDefaults: UserDefaults? = nil,
		ignoreExternalChanges: Bool? = nil,
		prefix: String? = nil,
		keychain: Keychain
	) {
		self.init(
			userDefaults: userDefaults,
			ignoreExternalChanges: ignoreExternalChanges,
			prefix: prefix
		)

		self.keychain = keychain
	}
}

public extension SonarrPreferences {
	enum Error: VisualError, Identifiable {
		case keychain(KeychainError)

		public var id: Self { self }

		public var title: String {
			switch self {
			case let .keychain(error):
				error.title
			}
		}

		public var systemName: String {
			switch self {
			case let .keychain(error):
				error.systemName
			}
		}

		public var subtitle: String {
			switch self {
			case let .keychain(error):
				error.subtitle
			}
		}
	}
}

public extension SonarrPreferences {
	func getServer() throws(Error) -> SonarrServer? {
		guard var server = server else { return nil }

		do {
			if let data = try keychain.data(for: .sonarrServer(server)) {
				server.apiKey = String(data: data, encoding: .utf8)
			}
		} catch {
			throw .keychain(error)
		}

		return server
	}

	func set(server: SonarrServer) throws(Error) {
		do {
			try keychain.removeData(for: .sonarrServer(server))

			if let apiKey = server.apiKey, let data = apiKey.data(using: .utf8) {
				try keychain.set(data, for: .sonarrServer(server))
			}
		} catch {
			throw .keychain(error)
		}

		self.server = server
	}

	func removeServer() throws(Error) {
		guard let server = server else { return }

		do {
			try keychain.removeData(for: .sonarrServer(server))
		} catch {
			throw .keychain(error)
		}

		self.server = nil
	}

	func reset() {
		guard let bundleIdentifier = Bundle.main.bundleIdentifier else { return }
		_userDefaults.removePersistentDomain(forName: bundleIdentifier)

		for (key, _) in _userDefaults.dictionaryRepresentation() {
			_userDefaults.removeObject(forKey: key)
		}
	}
}

public extension KeychainQuery {
	static func sonarrServer(_ server: SonarrServer) -> Self {
		.init(class: kSecClassGenericPassword as String, service: "sonarr-server", account: server.id)
	}
}
