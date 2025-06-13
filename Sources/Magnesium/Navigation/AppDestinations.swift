//
//  AppDestination.swift
//  Magnesium
//
//  Created by ninji on 12/06/2025.
//

import SwiftUI

enum AppDestination: RoutableDestinations {
	var id: Self { self }

	case torrent
	case addServer(ServerType)
	case editServer(Server)
	case addAServer
	case addNewServer(ServerType)
}

struct AppDestinations: ViewModifier {
	func body(content: Content) -> some View {
		content
			.navigationDestination(for: AppDestination.self) { destination in
				switch destination {
				case .torrent:
					TorrentsView()
				case .addServer(let server):
					switch server {
					case .deluge:
						AddDelugeServerView<AppRouter>()
					case .qbittorrent:
						AddQBittorrentServerView<AppRouter>()
					}
				case .editServer(let server):
					switch server.type {
					case .deluge:
						EditDelugeServerView<AppRouter>(server)
					case .qbittorrent:
						//						EditQBittorrentServerView()
						fatalError("Not yet implemented")
					}
				case .addNewServer(let server):
					switch server {
					case .deluge:
						AddDelugeServerView<AppRouter>()
					case .qbittorrent:
						AddQBittorrentServerView<AppRouter>()
					}
				case .addAServer:
					AddServerView()
				}
			}
	}
}

extension View {
	func withAppDestinations() -> some View {
		modifier(AppDestinations())
	}
}
