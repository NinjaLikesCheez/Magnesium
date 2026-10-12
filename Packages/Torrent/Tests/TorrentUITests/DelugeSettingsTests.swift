import Deluge
import Foundation
import Testing
import TorrentCore
import TorrentSession

@testable import TorrentUI

@Suite("DelugeSettings Tests")
@MainActor
struct DelugeSettingsTests {
	private func makeSettings(
		name: String = "Deluge",
		address: String = "http://localhost:8112",
		password: String = "deluge",
		basicAuthenticationUsername: String? = nil,
		basicAuthenticationPassword: String? = nil
	) -> DelugeSettings {
		DelugeSettings(
			name: name,
			address: address,
			password: password,
			basicAuthentication: .init(
				username: basicAuthenticationUsername,
				password: basicAuthenticationPassword
			)
		)
	}

	// MARK: - isValid Tests

	@Test("isValid is true when name, address, and password are set without basic authentication")
	func isValidWithRequiredFields() {
		#expect(makeSettings().isValid)
	}

	@Test("isValid is false when any required field is empty")
	func isValidRequiresAllRequiredFields() {
		#expect(!makeSettings(name: "").isValid)
		#expect(!makeSettings(address: "").isValid)
		#expect(!makeSettings(password: "").isValid)
	}

	@Test("isValid is true when both basic authentication fields are set")
	func isValidWithFullBasicAuthentication() {
		let settings = makeSettings(basicAuthenticationUsername: "user", basicAuthenticationPassword: "pass")
		#expect(settings.isValid)
	}

	@Test("isValid is false when only one basic authentication field is set")
	func isValidRejectsPartialBasicAuthentication() {
		#expect(!makeSettings(basicAuthenticationUsername: "user").isValid)
		#expect(!makeSettings(basicAuthenticationPassword: "pass").isValid)
	}

	@Test("isValid still requires name, address, and password when basic authentication is set")
	func isValidRequiresRequiredFieldsDespiteBasicAuthentication() {
		let settings = makeSettings(
			name: "",
			address: "",
			password: "",
			basicAuthenticationUsername: "user",
			basicAuthenticationPassword: "pass"
		)
		#expect(!settings.isValid)
	}

	// MARK: - makeServer Tests

	@Test("makeServer throws invalidState for an unparseable address")
	func makeServerRejectsInvalidURL() async {
		let settings = makeSettings(address: "")

		await #expect(throws: ServerSettingsError.invalidState(message: "Invalid URL, ensure you add http(s)://")) {
			try await settings.makeServer { _ in true }
		}
	}

	@Test("makeServer configures the client from the settings")
	func makeServerConfiguresClient() async throws {
		let settings = makeSettings(basicAuthenticationUsername: "user", basicAuthenticationPassword: "pass")

		var client: Deluge?
		_ = try await settings.makeServer {
			client = $0
			return true
		}

		let configured = try #require(client)
		#expect(configured.baseURL == URL(string: "http://localhost:8112/json"))
		#expect(configured.password == "deluge")
		#expect(configured.basicAuthentication == BasicAuthentication(username: "user", password: "pass"))
	}

	@Test("makeServer omits basic authentication from the client when not fully set")
	func makeServerOmitsPartialBasicAuthentication() async throws {
		let settings = makeSettings(basicAuthenticationUsername: "user")

		var client: Deluge?
		_ = try await settings.makeServer {
			client = $0
			return true
		}

		#expect(try #require(client).basicAuthentication == nil)
	}

	@Test("makeServer throws unableToAuthenticate when the server rejects the password")
	func makeServerRejectedAuthentication() async {
		let settings = makeSettings()

		await #expect(throws: ServerSettingsError.unableToAuthenticate) {
			try await settings.makeServer { _ in false }
		}
	}

	@Test("makeServer returns a server whose payloads round-trip through Codable")
	func makeServerSuccess() async throws {
		let settings = makeSettings(basicAuthenticationUsername: "user", basicAuthenticationPassword: "pass")

		let server = try await settings.makeServer { _ in true }

		#expect(server.name == "Deluge")
		#expect(server.type == .deluge)

		let decoder = JSONDecoder()

		let serverSettings = try decoder.decode(DelugeServerSettings.self, from: server.data)
		#expect(serverSettings.url == URL(string: "http://localhost:8112"))

		let keychain = try decoder.decode(DelugeKeychainData.self, from: try #require(server.keychainData))
		#expect(keychain.password == "deluge")
		#expect(keychain.basicAuthentication == BasicAuthentication(username: "user", password: "pass"))
	}

	@Test("makeServer translates client errors into ServerSettingsError")
	func makeServerErrorTranslation() async {
		let underlying = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "boom"])
		let urlError = URLError(.timedOut)

		let expectations: [(Deluge.Error, ServerSettingsError)] = [
			(.encoding(underlying), .invalidState(message: "boom")),
			(.decoding(underlying), .invalidState(message: "boom")),
			(.request(.urlError(urlError)), .request(message: urlError.localizedDescription)),
			(.request(.invalidRequest(underlying)), .request(message: "boom")),
			(.request(.unknown(underlying)), .unknown(message: "boom")),
			(.response(.message("server exploded")), .invalidState(message: "server exploded")),
			(.response(.message(nil)), .unknown(message: "Please try again later")),
			(.response(.unauthenticated), .unableToAuthenticate),
			(.response(.unconnected), .unknown(message: "Please try again later!")),
			(.response(.unknownMethod), .unknown(message: "Please try again later!")),
		]

		for (clientError, expected) in expectations {
			let settings = makeSettings()

			await #expect(throws: expected) {
				try await settings.makeServer { (_: Deluge) async throws(Deluge.Error) -> Bool in
					throw clientError
				}
			}
		}
	}
}
