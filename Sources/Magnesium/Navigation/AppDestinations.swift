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
	case detail(StandardTorrent)
}

struct AppDestinations: ViewModifier {
	func body(content: Content) -> some View {
		content
			.navigationDestination(for: AppDestination.self) { destination in
				switch destination {
				case .torrent:
					TorrentsView()
				case let .detail(torrent):
					TorrentDetailView(torrent: torrent)
				}
			}
	}
}

extension View {
	func withAppDestinations() -> some View {
		modifier(AppDestinations())
	}
}
