//
//  AppPreferences.swift
//  Magnesium
//
//  Created by ninji on 09/04/2025.
//
import Foundation
import Observation

@Observable
public final class AppPreferences {
	// TODO: a macro would be useful here....
	var autoRefreshInterval: TimeInterval {
		get {
			access(keyPath: \.autoRefreshInterval)
			return preferences[.autoRefreshInterval]
		}
		set {
			withMutation(keyPath: \.autoRefreshInterval) {
				preferences[.autoRefreshInterval] = newValue
			}
		}
	}

	var servers: [Server] {
		get {
			access(keyPath: \.servers)
			return preferences[.servers]
		}
		set {
			withMutation(keyPath: \.servers) {
				preferences[.servers] = newValue
			}
		}
	}

	var selectedServerID: String? {
		get {
			access(keyPath: \.selectedServerID)
			return preferences[.selectedServerID]
		}
		set {
			withMutation(keyPath: \.selectedServerID) {
				preferences[.selectedServerID] = newValue
			}
		}
	}

	var sortOption: SortOption {
		get {
			access(keyPath: \.sortOption)
			return preferences[.sortOption]
		}
		set {
			withMutation(keyPath: \.sortOption) {
				preferences[.sortOption] = newValue
			}
		}
	}

	var filterOptions: FilterOptions {
		get {
			access(keyPath: \.filterOptions)
			return preferences[.filterOptions]
		}
		set {
			withMutation(keyPath: \.filterOptions) {
				preferences[.filterOptions] = newValue
			}
		}
	}

	@ObservationIgnored
	private var preferences: Preferences

	init(_ preferences: Preferences) {
		self.preferences = preferences
	}
}

extension AppPreferences {
	func removeValue<T>(for key: PreferenceKey<T>) {
		preferences.removeValue(for: key)
		// TODO: can we build a list of keypaths to access the properties to handle things nicer?
	}
}

extension AppPreferences {
//	private func keypath<T>(for identifier: PreferenceKey<T>) -> PartialKeyPath<AppPreferences> {
//		
//	}

	private func updateSelectedServerID() throws {
		guard let server = try getSelectedServer() else {
			preferences.removeValue(for: .selectedServerID)
			selectedServerID = nil
			return
		}

		selectedServerID = server.id
	}

	func getSelectedServer() throws -> Server? {
		let servers = try getServers()
		guard let selectedServerID = selectedServerID else { return servers.first }
		return servers.first { $0.id == selectedServerID } ?? servers.first
	}

	func getServers() throws -> [Server] {
		var servers = servers
		for (index, server) in servers.enumerated() {
			var server = server
			server.keychainData = try Current.keychain.data(for: .server(server))
			servers[index] = server
		}

		return servers
	}

	func addOrUpdate(server: Server) throws {
		var servers = try getServers()

		if let index = servers.firstIndex(where: { $0.id == server.id }) {
			servers[index] = server
		} else {
			servers.append(server)
		}

		for server in servers {
			try Current.keychain.removeData(for: .server(server))

			if let data = server.keychainData {
				try Current.keychain.set(data, for: .server(server))
			}
		}

		self.servers = servers
		try updateSelectedServerID()
	}

	func remove(server: Server) throws {
		var servers = try getServers()
		servers.removeAll { $0.id == server.id }
		try Current.keychain.removeData(for: .server(server))
		self.servers = servers
		try updateSelectedServerID()
	}

	func removeServers() throws {
		try Current.keychain.removeData(for: .servers)
		removeValue(for: .servers)
		removeValue(for: .selectedServerID)
		servers = []
		selectedServerID = nil
	}}
