//
//  SettingsDestination.swift
//  Magnesium
//
//  Created by ninji on 12/06/2025.
//

import Router
import SwiftUI

/// Navigation destinations for the Settings feature.
public enum TorrentSettingsDestination: RoutableDestination {
	public var id: Self { self }

	/// Navigate to edit an existing server's configuration
	case editServer(TorrentServer)

	/// Navigate to the server selection screen where users can choose which type of server to add
	case addAServer

	/// Navigate directly to add a specific server type
	case addNewServer(TorrentServerType)
}

struct TorrentSettingsDestinationModifier: RoutableDestinationViewModifier {
	func body(content: Content) -> some View {
		content
			.navigationDestination(for: TorrentSettingsDestination.self) { destination in
				switch destination {
				case .addAServer:
					AddServerView()
				case let .addNewServer(type):
					switch type {
					case .deluge:
						AddDelugeServerView<TorrentSettingsRouter>()
					case .qbittorrent:
						AddQBittorrentServerView<TorrentSettingsRouter>()
					}
				case .editServer(let server):
					switch server.type {
					case .deluge:
						EditDelugeServerView(server)
					case .qbittorrent:
						//						EditQBittorrentServerView()
						fatalError("Not yet implemented")
					}
				}
			}
	}
}

extension View {
	func withTorrentSettingsDestinations() -> some View {
		modifier(TorrentSettingsDestinationModifier())
	}
}
