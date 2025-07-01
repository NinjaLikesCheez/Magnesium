//
//  SettingsDestination.swift
//  Magnesium
//
//  Created by ninji on 12/06/2025.
//

import SwiftUI

enum SettingsDestinations: RoutableDestinations {
	var id: Self { self }

	case editServer(Server)
	case addAServer
	case addNewServer(ServerType)
}

struct SettingsDestinationsModifier: ViewModifier {
	func body(content: Content) -> some View {
		content
			.navigationDestination(for: SettingsDestinations.self) { destination in
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
		modifier(SettingsDestinationsModifier())
	}
}
