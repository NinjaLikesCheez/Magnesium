//
//  AppPreferences.swift
//  Magnesium
//
//  Created by ninji on 09/04/2025.
//
import Foundation
import ObservableDefaults

// TODO: fork this or use @AppStorage or something to allow for a custom init
@ObservableDefaults
public final class AppPreferences: Preferences {
	var autoRefreshInterval: TimeInterval = 2.0

	// TODO: Create a fork of observable defaults that allows you to transform before storing or something - servers can have keychainData which should be stored in the keychain and not in defaults
	var servers: [Server] = []

	var selectedServerID: String? = nil

	var sortOption: SortOption = .init(property: .dateAdded)

	var filterOptions: FilterOptions = .init()

	var automaticallyLookForMagnetLinks: Bool = false

	@Ignore
	private var keychain: Keychain!

	convenience init(
		userDefaults: UserDefaults? = nil,
		ignoreExternalChanges: Bool? = nil,
		prefix: String? = nil,
		ignoredKeyPathsForExternalUpdates: [PartialKeyPath<AppPreferences>] = [],
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

extension AppPreferences {
	enum Error: VisualError {
		case keychain(KeychainError)
	}
}

extension AppPreferences {
	private func updateSelectedServerID() throws(Error) {
		guard let server = try getSelectedServer() else {
			selectedServerID = nil
			return
		}

		selectedServerID = server.id
	}

	func getSelectedServer() throws(Error) -> Server? {
		let servers = try getServers()
		guard let selectedServerID = selectedServerID else { return servers.first }
		return servers.first { $0.id == selectedServerID } ?? servers.first
	}

	func getServers() throws(Error) -> [Server] {
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

	func addOrUpdate(server: Server) throws(Error) {
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

	func remove(server: Server) throws(Error) {
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
