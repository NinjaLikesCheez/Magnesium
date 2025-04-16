//
//  AppPreferences.swift
//  Magnesium
//
//  Created by ninji on 09/04/2025.
//
import Foundation
import ObservableDefaults

@ObservableDefaults
public final class AppPreferences {
	var autoRefreshInterval: TimeInterval = 2.0

	var servers: [Server] = []

	var selectedServerID: String? = nil

	var sortOption: SortOption = .init(property: .dateAdded)

	var filterOptions: FilterOptions = .init()

	var automaticallyLookForMagnetLinks: Bool = false

	init() {}
}

extension AppPreferences {
	private func updateSelectedServerID() throws {
		guard let server = try getSelectedServer() else {
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
		servers = []
		selectedServerID = nil
	}

	func reset() {
		guard let bundleIdentifier = Bundle.main.bundleIdentifier else { return }
		_userDefaults.removePersistentDomain(forName: bundleIdentifier)
	}
}
