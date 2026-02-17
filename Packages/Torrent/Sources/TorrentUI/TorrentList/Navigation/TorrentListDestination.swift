//
//  SettingsDestinations.swift
//  Magnesium
//
//  Created by ninji on 25/06/2025.
//
import Router
import SwiftUI

/// Navigation destinations for the TorrentList feature.
public enum TorrentListDestination: RoutableDestination {
	public var id: Self { self }

	/// Navigate to the detailed view of a specific torrent
	case detail(StandardTorrent)
}

struct TorrentListDestinationModifier: ViewModifier {
	let manager: TorrentManager

	func body(content: Content) -> some View {
		content
			.navigationDestination(for: TorrentListDestination.self) {  destination in
				switch destination {
				case let .detail(torrent):
					TorrentDetailView(torrent: torrent)
						.environment(manager)
				}
			}
	}
}

extension View {
	func withTorrentListDestinations(manager: TorrentManager) -> some View {
		modifier(TorrentListDestinationModifier(manager: manager))
	}
}
