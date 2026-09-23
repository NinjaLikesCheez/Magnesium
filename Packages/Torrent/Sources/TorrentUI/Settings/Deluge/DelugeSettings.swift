//
//  DelugeSettings.swift
//  Magnesium
//
//  Created by ninji on 11/04/2025.
//
import Deluge
import Foundation
import Observation
import TorrentSession

// TODO: this could probably live elsewhere

@MainActor
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
		#if DEBUG
			self.name = "Deluge"
			self.address = "http://proxyman.debug:8112"
			self.password = "deluge"
			self.basicAuthentication = .init()
		#else
			self.name = ""
			self.address = ""
			self.password = ""
			self.basicAuthentication = .init()
		#endif
	}

	var isValid: Bool {
		// Basic auth is optional, but username/password must both be present or both be absent.
		!name.isEmpty && !address.isEmpty && !password.isEmpty
			&& basicAuthentication.username.isEmpty == basicAuthentication.password.isEmpty
	}

	func makeServer(
		authenticate: (Deluge) async throws(Deluge.Error) -> Bool = { client in
			try await client.request(.authenticate(client.password))
		}
	) async throws(ServerSettingsError) -> TorrentServer {
		guard let url = URL(string: address) else {
			throw .invalidState(message: "Invalid URL, ensure you add http(s)://")
		}

		let client = Deluge(
			baseURL: url,
			password: password,
			basicAuthentication: basicAuthentication.toAPIClient()
		)

		let authenticated: Bool

		do throws(Deluge.Error) {
			authenticated = try await authenticate(client)
			if !authenticated {
				throw Deluge.Error.response(.unauthenticated)
			}
		} catch {
			throw error.intoServerSettingsError()
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

fileprivate extension Deluge.Error {
	func intoServerSettingsError() -> ServerSettingsError {
		switch self {
		case let .encoding(error):
			.invalidState(message: error.localizedDescription)
		case let .decoding(error):
			.invalidState(message: error.localizedDescription)
		case let .request(error):
			error.intoServerSettingsError()
		case let .response(error):
			error.intoServerSettingsError()
		}
	}
}

fileprivate extension Deluge.ResponseError {
	func intoServerSettingsError() -> ServerSettingsError {
		switch self {
		case let .message(message: message):
			if let message {
				.invalidState(message: message)
			} else {
				.unknown(message: "Please try again later")
			}
		case .unauthenticated:
			.unableToAuthenticate
		default:
			.unknown(message: "Please try again later!")
		}
	}
}

fileprivate extension RequestError {
	func intoServerSettingsError() -> ServerSettingsError {
		switch self {
		case let .urlError(error):
			.request(message: error.localizedDescription)
		case let .invalidRequest(error):
			.request(message: error.localizedDescription)
		case let .unknown(error):
			.unknown(message: error.localizedDescription)
		}
	}
}
