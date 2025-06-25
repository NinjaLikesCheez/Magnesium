//
//  SettingsDestinations.swift
//  Magnesium
//
//  Created by ninji on 25/06/2025.
//
import SwiftUI

enum TorrentListDestination: RoutableDestinations {
	var id: Self { self }

	case detail(StandardTorrent)
}

struct TorrentListDestinationModifier: ViewModifier {
	func body(content: Content) -> some View {
		content
			.navigationDestination(for: TorrentListDestination.self) { destination in
				switch destination {
				case let .detail(torrent):
					TorrentDetailView(torrent: torrent)
				}
			}
	}
}

extension View {
	func withTorrentListDestinations() -> some View {
		modifier(TorrentListDestinationModifier())
	}
}
