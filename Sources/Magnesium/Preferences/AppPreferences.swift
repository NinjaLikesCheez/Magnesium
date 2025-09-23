//
//  AppPreferences.swift
//  Magnesium
//
//  Created by ninji on 09/04/2025.
//
import Foundation
import ObservableDefaults
import Common

// TODO: fork this or use @AppStorage or something to allow for a custom init
@ObservableDefaults
final class AppPreferences: Preferences {
	var autoRefreshInterval: TimeInterval = 2.0

	// TODO: Create a fork of observable defaults that allows you to transform before storing or something - servers can have keychainData which should be stored in the keychain and not in defaults
	public var servers: [Server] = []

	public var selectedServerID: String? = nil

	public var sortOption: SortOption = .init(property: .dateAdded)

	public var filterOptions: FilterOptions = .init()

	public var automaticallyLookForMagnetLinks: Bool = false

	@Ignore
	private var keychain: Keychain!

	public convenience init(
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
	public enum Error: VisualError {
		case keychain(KeychainError)

		var title: String {
			switch self {
			case let .keychain(error):
				error.title
			}
		}

		var systemName: String {
			switch self {
			case let .keychain(error):
				error.systemName
			}
		}

		var subtitle: String {
			switch self {
			case let .keychain(error):
				error.subtitle
			}
		}
	}
}

extension AppPreferences.Error: Equatable {
	static func == (lhs: AppPreferences.Error, rhs: AppPreferences.Error) -> Bool {
		switch (lhs, rhs) {
		case let (.keychain(lhs), .keychain(rhs)):
			// Prefer structural equality if available, otherwise fall back to a stable string description
			return lhs == rhs
		}
	}
}

extension AppPreferences.Error: Hashable {
	func hash(into hasher: inout Hasher) {
		switch self {
		case let .keychain(error):
			// Use a stable textual representation to hash when underlying type may not be Hashable
			hasher.combine("keychain")
			hasher.combine(String(describing: error))
		}
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

	public func getSelectedServer() throws(Error) -> Server? {
		let servers = try getServers()
		guard let selectedServerID = selectedServerID else { return servers.first }
		return servers.first { $0.id == selectedServerID } ?? servers.first
	}

	public func getServers() throws(Error) -> [Server] {
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

	public func addOrUpdate(server: Server) throws(Error) {
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

	public func remove(server: Server) throws(Error) {
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

	public func removeServers() throws(Error) {
		do {
			try keychain.removeData(for: .servers)
		} catch {
			throw .keychain(error)
		}
		servers = []
		selectedServerID = nil
	}

	public func reset() {
		guard let bundleIdentifier = Bundle.main.bundleIdentifier else { return }
		_userDefaults.removePersistentDomain(forName: bundleIdentifier)

		// In tests, the above doesn't work
		for (key, _) in _userDefaults.dictionaryRepresentation() {
			_userDefaults.removeObject(forKey: key)
		}
	}
}
