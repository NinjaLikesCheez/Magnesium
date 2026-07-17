import Deluge
import Observation
import SwiftUI
import TorrentUI

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
	@Environment(SettingsRouter.self) var router

	var body: some View {
		List(TorrentServerType.allCases) { server in
			// TODO: this
//			NavigationLink(value: SettingsDestination.addNewServer(server)) {
				Text(server.localizedString)
					.fixedSize()
					.foregroundStyle(.primary)
//			}
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
