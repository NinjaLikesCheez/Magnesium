//
//  DelugeSettings.swift
//  Magnesium
//
//  Created by ninji on 11/04/2025.
//
import Deluge
import Foundation
import Observation

@Observable
class DelugeSettings {
	var name: String
	var address: String
	var password: String
	var basicAuthentication: ServerBasicAuthentication

	init(name: String, address: String, password: String, basicAuthentication: ServerBasicAuthentication) {
		self.name = name
		self.address = address
		self.password = password
		self.basicAuthentication = basicAuthentication
	}

	init() {
		self.name = ""
		self.address = ""
		self.password = ""
		self.basicAuthentication = .init()
	}

	func makeServer() async throws(ServerSettingsItem.Error) -> Server {
		guard let url = URL(string: address) else {
			throw .invalidState(message: "Invalid URL, ensure you add http(s)://")
		}

		let client = Current.deluge(url, password, basicAuthentication.toAPIClient())
		let authenticated: Bool

		do throws(Deluge.Error) {
			authenticated = try await client.request(.authenticate(password))
			if !authenticated {
				throw Deluge.Error.response(.unauthenticated)
			}
		} catch {
			throw .unableToAuthenticate
		}

		let serverSettings = DelugeServerSettings(url: url)
		let keychain = DelugeKeychainData(
			password: password,
			basicAuthentication: basicAuthentication.toAPIClient()
		)

		let encoder = JSONEncoder()
		let data: Data
		let keychainData: Data

		do {
			data = try encoder.encode(serverSettings)
			keychainData = try encoder.encode(keychain)
		} catch {
			throw .invalidState(message: error.localizedDescription)
		}

		return .init(
			name: name,
			type: .deluge,
			data: data,
			keychainData: keychainData
		)
	}
}
