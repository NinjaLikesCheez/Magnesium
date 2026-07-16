//
//  TorrentOnboardingDestination.swift
//  Magnesium
//
//  Created by ninji on 12/06/2025.
//

import Router
import SwiftUI

/// Navigation destinations for the Onboarding feature.
public enum TorrentOnboardingDestination: RoutableDestination {
	var id: Self { self }

	/// Add a new server of a specific type
	case addNewServer(TorrentServerType)
}

struct TorrentOnboardingDestinationModifier: RoutableDestinationViewModifier {
	func body(content: Content) -> some View {
		content
			.navigationDestination(for: TorrentOnboardingDestination.self) { destination in
				switch destination {
				case let .addNewServer(type):
					switch type {
					case .deluge:
						OnboardingAddDelugeServerView()
					case .qbittorrent:
						OnboardingAddQBittorrentServerView()
					}
				}
			}
	}
}

extension View {
	func withTorrentOnboardingDestinations() -> some View {
		modifier(TorrentOnboardingDestinationModifier())
	}
}
