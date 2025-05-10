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

struct AddServerView: View {
	@Environment(Router.self) var router

	var body: some View {
		List(ServerType.allCases) { server in
			RoutableNavigationLink {
				Text(server.localizedString)
					.fixedSize()
			} action: {
				switch server {
				case .deluge:
					router.push(SettingsCoordinator.Destinations.addServer(.deluge))
				case .qbittorrent:
					router.push(SettingsCoordinator.Destinations.addServer(.qbittorrent))
				}
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
