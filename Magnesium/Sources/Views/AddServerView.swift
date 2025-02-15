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
			saveServerAction: { () async throws(ServerSettingsItem.Error) in
			},
			saveServerButtonEnabled: { basicAuthenticationEnabled in
				!name.isEmpty && !address.isEmpty && !username.isEmpty && !password.isEmpty
					&& (!basicAuthenticationEnabled
						|| !basicAuthentication.username.isEmpty && !basicAuthentication.password.isEmpty)
			}
		)
	}
}

struct QBittorrentServerSettingsView: View {
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
			saveServerAction: { () async throws(ServerSettingsItem.Error) in
			},
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
			.navigationTitle("Server Type")
			#if !os(macOS)
				.listStyle(.insetGrouped)
			#else
				.listStyle(.bordered)
			#endif
		}

	}
}
