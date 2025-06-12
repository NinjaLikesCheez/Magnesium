//
//  AppDestination.swift
//  Magnesium
//
//  Created by ninji on 12/06/2025.
//

import SwiftUI

enum AppDestination: RoutableDestination {
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
						AddDelugeServerView()
					case .qbittorrent:
						AddQBittorrentServerView()
					}
				case .editServer(let server):
					switch server.type {
					case .deluge:
						EditDelugeServerView(server)
					case .qbittorrent:
						//						EditQBittorrentServerView()
						fatalError("Not yet implemented")
					}
				case .addNewServer(let server):
					switch server {
					case .deluge:
						AddDelugeServerView()
					case .qbittorrent:
						AddQBittorrentServerView()
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
