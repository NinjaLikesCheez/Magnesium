import Deluge
import Observation
import SwiftUI
import SwiftNavigation
import CommonUI

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
	@Environment(TorrentPreferences.self) private var preferences

	@State private var model: Model = .init()

	var body: some View {
		List(TorrentServerType.allCases) { server in
			NavigationButton(server.localizedString) {
				model.destination = .addNewServer(server)
			}
		}
		.navigationTitle("Add Server")
		.navigationBarTitleDisplayMode(.inline)
		#if !os(macOS)
			.listStyle(.insetGrouped)
		#else
			.listStyle(.bordered)
		#endif
			.navigationDestination(item: $model.destination) { destination in
				switch destination {
				case let .addNewServer(type):
					switch type {
					case .deluge:
						AddDelugeServerView()
							.environment(preferences)
					case .qbittorrent:
						AddQBittorrentServerView()
							.environment(preferences)
					}
				}
			}
	}

	@Observable
	final class Model {
		var destination: Destination?

		@CasePathable
		enum Destination {
			case addNewServer(TorrentServerType)
		}
	}
}
