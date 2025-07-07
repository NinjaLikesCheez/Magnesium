//
//  SettingsDestination.swift
//  Magnesium
//
//  Created by ninji on 12/06/2025.
//

import SwiftUI

/// Navigation destinations for the Settings feature.
enum SettingsDestination: RoutableDestination {
	var id: Self { self }

	/// Navigate to edit an existing server's configuration
	case editServer(Server)

	/// Navigate to the server selection screen where users can choose which type of server to add
	case addAServer

	/// Navigate directly to add a specific server type
	case addNewServer(ServerType)
}

struct SettingsDestinationModifier: RoutableDestinationViewModifier {
	func body(content: Content) -> some View {
		content
			.navigationDestination(for: SettingsDestination.self) { destination in
				switch destination {
				case .addAServer:
					AddServerView()
				case let .addNewServer(type):
					switch type {
					case .deluge:
						AddDelugeServerView<SettingsRouter>()
					case .qbittorrent:
						AddQBittorrentServerView<SettingsRouter>()
					}
				case .editServer(let server):
					switch server.type {
					case .deluge:
						EditDelugeServerView<SettingsRouter>(server)
					case .qbittorrent:
						//						EditQBittorrentServerView()
						fatalError("Not yet implemented")
					}
				}
			}
	}
}

extension View {
	func withSettingsDestinations() -> some View {
		modifier(SettingsDestinationModifier())
	}
}
