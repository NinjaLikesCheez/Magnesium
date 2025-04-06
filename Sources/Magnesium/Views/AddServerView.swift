import Deluge
import Observation
import SwiftUI

@Observable
class ServerBasicAuthentication {
	var username: String = ""
	var password: String = ""

	init(username: String? = nil, password: String? = nil) {
		self.username = username ?? ""
		self.password = password ?? ""
	}

	func toAPIClient() -> BasicAuthentication? {
		guard !username.isEmpty && !password.isEmpty else {
			return nil
		}

		return .init(username: username, password: password)
	}
}

extension BasicAuthentication {
	func toServerBasicAuthentication() -> ServerBasicAuthentication {
		ServerBasicAuthentication(username: username, password: password)
	}
}

struct TransmissionServerSettingsView: View {
	@State private var name: String = ""
	@State private var address: String = ""
	@State private var username: String = ""
	@State private var password: String = ""
	@State private var basicAuthentication = ServerBasicAuthentication()

	var body: some View {
		ServerSettingsView(
			name: $name,
			address: $address,
			username: $username,
			password: $password,
			basicAuthentication: $basicAuthentication,
			makeServer: { fatalError("Not implemented") },
			saveServerButtonEnabled: { basicAuthenticationEnabled in
				!name.isEmpty && !address.isEmpty && !username.isEmpty && !password.isEmpty
					&& (!basicAuthenticationEnabled
						|| !basicAuthentication.username.isEmpty && !basicAuthentication.password.isEmpty)
			}
		)
	}
}

struct QBittorrentServerSettingsView: View {
	@State private var name: String
	@State private var address: String
	@State private var username: String
	@State private var password: String
	@State private var basicAuthentication: ServerBasicAuthentication

	init(_ server: Server? = nil) {
		if let server {
			name = server.name

			let settings = try? JSONDecoder().decode(QBittorrentServerSettings.self, from: server.data)
			let keychain = server.keychainData.flatMap { try? JSONDecoder().decode(QBittorrentKeychainData.self, from: $0) }

			address = settings?.url.absoluteString ?? ""
			username = keychain?.username ?? ""
			password = keychain?.password ?? ""
			basicAuthentication = keychain?.basicAuthentication?.toServerBasicAuthentication() ?? ServerBasicAuthentication()
		} else {
			name = ""
			address = ""
			username = ""
			password = ""
			basicAuthentication = ServerBasicAuthentication()
		}
	}

	var body: some View {
		ServerSettingsView(
			name: $name,
			address: $address,
			username: $username,
			password: $password,
			basicAuthentication: $basicAuthentication,
			makeServer: { fatalError("Not implemented") },
			saveServerButtonEnabled: { basicAuthenticationEnabled in
				!name.isEmpty && !address.isEmpty && !username.isEmpty && !password.isEmpty
					&& (!basicAuthenticationEnabled
						|| !basicAuthentication.username.isEmpty && !basicAuthentication.password.isEmpty)
			}
		)
	}
}

struct AddServerView: View {
	var body: some View {
		NavigationStack {
			List(ServerType.allCases) { server in
				NavigationLink {
					switch server {
					case .deluge:
						DelugeServerSettingsView()
					case .qbittorrent:
						QBittorrentServerSettingsView()
					}
				} label: {
					Text(server.localizedString)
						.fixedSize()
				}
			}
			.navigationTitle("Add Server")
			.navigationBarTitleDisplayMode(.inline)
			#if !os(macOS)
				.listStyle(.insetGrouped)
			#else
				.listStyle(.bordered)
			#endif
		}

	}
}
