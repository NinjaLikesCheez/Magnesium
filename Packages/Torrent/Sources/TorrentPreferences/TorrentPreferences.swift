import Common
//
//  TorrentPreferences.swift
//  Magnesium
//
//  Created by ninji on 09/04/2025.
//
import Foundation
import ObservableDefaults

// TODO: fork this or use @AppStorage or something to allow for a custom init
@ObservableDefaults
@MainActor
public final class TorrentPreferences: Preferences {
	public var autoRefreshInterval: TimeInterval = 2.0

	// TODO: Create a fork of observable defaults that allows you to transform before storing or something - servers can have keychainData which should be stored in the keychain and not in defaults
	public var servers: [TorrentServer] = []

	public var selectedServerID: String? = nil

	public var sortOption: TorrentSortOption = .init(property: .dateAdded)

	public var filterOptions: TorrentFilterOptions = .init()

	public var automaticallyLookForMagnetLinks: Bool = false

	@Ignore
	private var keychain: Keychain!

	public convenience init(
		userDefaults: UserDefaults? = nil,
		ignoreExternalChanges: Bool? = nil,
		prefix: String? = nil,
		ignoredKeyPathsForExternalUpdates: [PartialKeyPath<TorrentPreferences>] = [],
		keychain: Keychain
	) {
		self.init(
			userDefaults: userDefaults,
			ignoreExternalChanges: ignoreExternalChanges,
			prefix: prefix,
			ignoredKeyPathsForExternalUpdates: ignoredKeyPathsForExternalUpdates
		)

		self.keychain = keychain
	}
}

public extension TorrentPreferences {
	enum Error: VisualError {
		case keychain(KeychainError)

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

public extension TorrentPreferences {
	private func updateSelectedServerID() throws(Error) {
		guard let server = try getSelectedServer() else {
			selectedServerID = nil
			return
		}

		selectedServerID = server.id
	}

	func getSelectedServer() throws(Error) -> TorrentServer? {
		let servers = try getServers()
		guard let selectedServerID = selectedServerID else { return servers.first }
		return servers.first { $0.id == selectedServerID } ?? servers.first
	}

	func getServers() throws(Error) -> [TorrentServer] {
		var servers = servers
		for (index, server) in servers.enumerated() {
			var server = server
			do {
				server.keychainData = try keychain.data(for: .server(server))
			} catch {
				throw .keychain(error)
			}
			servers[index] = server
		}

		return servers
	}

	func addOrUpdate(server: TorrentServer) throws(Error) {
		var servers = try getServers()

		if let index = servers.firstIndex(where: { $0.id == server.id }) {
			servers[index] = server
		} else {
			servers.append(server)
		}

		do {
			try keychain.removeData(for: .server(server))

			if let data = server.keychainData {
				try keychain.set(data, for: .server(server))
			}
		} catch {
			throw .keychain(error)
		}

		self.servers = servers
		try updateSelectedServerID()
	}

	func remove(server: TorrentServer) throws(Error) {
		var servers = try getServers()
		servers.removeAll { $0.id == server.id }
		do {
			try keychain.removeData(for: .server(server))
		} catch {
			throw .keychain(error)
		}
		self.servers = servers
		try updateSelectedServerID()
	}

	func removeServers() throws(Error) {
		do {
			try keychain.removeData(for: .servers)
		} catch {
			throw .keychain(error)
		}
		servers = []
		selectedServerID = nil
	}

	func reset() {
		guard let bundleIdentifier = Bundle.main.bundleIdentifier else { return }
		_userDefaults.removePersistentDomain(forName: bundleIdentifier)

		// In tests, the above doesn't work
		for (key, _) in _userDefaults.dictionaryRepresentation() {
			_userDefaults.removeObject(forKey: key)
		}
	}
}

public extension KeychainQuery {
	static var servers: Self {
		.init(class: kSecClassGenericPassword as String, service: "servers")
	}

	static func server(_ server: TorrentServer) -> Self {
		.init(class: kSecClassGenericPassword as String, service: "servers", account: server.id)
	}
}
