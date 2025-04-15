import Deluge
import SwiftUI

struct DelugeServerSettingsView: View {
	@State private var settings: DelugeSettings
	@State private var server: Server?
	private var editingExistingServer = false

	init(_ server: Server? = nil) {
		if let server {
			let serverSettings = try? JSONDecoder().decode(DelugeServerSettings.self, from: server.data)
			let keychain = server.keychainData.flatMap { try? JSONDecoder().decode(DelugeKeychainData.self, from: $0) }

			settings = .init(
				name: server.name,
				address: serverSettings?.url.absoluteString ?? "",
				password: keychain?.password ?? "",
				basicAuthentication: keychain?.basicAuthentication?.toServerBasicAuthentication() ?? ServerBasicAuthentication()
			)
		} else {
			settings = .init()
		}
	}

	var body: some View {
		ServerSettingsView(
			name: $settings.name,
			address: $settings.address,
			password: $settings.password,
			basicAuthentication: $settings.basicAuthentication,
			makeServer: { () async throws(ServerSettingsItem.Error) in
				guard let url = URL(string: settings.address) else {
					throw .invalidState(message: "Invalid URL, ensure you add http(s)://")
				}

				let client = Current.deluge(url, settings.password, settings.basicAuthentication.toAPIClient())
				let authenticated: Bool

				do throws(Deluge.Error) {
					authenticated = try await client.request(.authenticate(settings.password))
					if !authenticated {
						throw Deluge.Error.response(.unauthenticated)
					}
				} catch {
					throw .unableToAuthenticate
				}

				let serverSettings = DelugeServerSettings(url: url)
				let keychain = DelugeKeychainData(
					password: settings.password,
					basicAuthentication: settings.basicAuthentication.toAPIClient()
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
					name: settings.name,
					type: .deluge,
					data: data,
					keychainData: keychainData
				)
			},
			saveServerButtonEnabled: { basicAuthenticationEnabled in
				!settings.name.isEmpty && !settings.address.isEmpty && URL(string: settings.address) != nil && !settings.password.isEmpty
					&& (!basicAuthenticationEnabled
							|| !settings.basicAuthentication.username.isEmpty && !settings.basicAuthentication.password.isEmpty)
			}
		)
		.navigationTitle("Deluge Settings")
	}
}
