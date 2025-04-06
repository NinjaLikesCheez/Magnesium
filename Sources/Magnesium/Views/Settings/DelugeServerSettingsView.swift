import Deluge
import SwiftUI

struct DelugeServerSettingsView: View {
	@State private var name: String
	@State private var address: String
	@State private var password: String
	@State private var basicAuthentication: ServerBasicAuthentication

	@State private var server: Server?

	init(_ server: Server? = nil) {
		if let server {
			name = server.name

			let settings = try? JSONDecoder().decode(DelugeServerSettings.self, from: server.data)
			let keychain = server.keychainData.flatMap { try? JSONDecoder().decode(DelugeKeychainData.self, from: $0) }

			address = settings?.url.absoluteString ?? ""
			password = keychain?.password ?? ""
			basicAuthentication = keychain?.basicAuthentication?.toServerBasicAuthentication() ?? ServerBasicAuthentication()
		} else {
			name = ""
			address = ""
			password = ""
			basicAuthentication = ServerBasicAuthentication()
		}
	}

	var body: some View {
		ServerSettingsView(
			name: $name,
			address: $address,
			password: $password,
			basicAuthentication: $basicAuthentication,
			makeServer: { () async throws(ServerSettingsItem.Error) in
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

				let settings = DelugeServerSettings(url: url)
				let keychain = DelugeKeychainData(
					password: password,
					basicAuthentication: basicAuthentication.toAPIClient()
				)

				let encoder = JSONEncoder()
				let data: Data
				let keychainData: Data

				do {
					data = try encoder.encode(settings)
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
			},
			saveServerButtonEnabled: { basicAuthenticationEnabled in
				!name.isEmpty && !address.isEmpty && URL(string: address) != nil && !password.isEmpty
					&& (!basicAuthenticationEnabled
						|| !basicAuthentication.username.isEmpty && !basicAuthentication.password.isEmpty)
			}
		)
	}
}
