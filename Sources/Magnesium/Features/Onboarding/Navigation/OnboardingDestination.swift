//
//  OnboardingDestination.swift
//  Magnesium
//
//  Created by ninji on 12/06/2025.
//

import Router
import SwiftUI

/// Navigation destinations for the Onboarding feature.
enum OnboardingDestination: RoutableDestination {
	var id: Self { self }

	/// Add a new server of a specific type
	case addNewServer(ServerType)
}

struct OnboardingDestinationModifier: RoutableDestinationViewModifier {
	func body(content: Content) -> some View {
		content
			.navigationDestination(for: OnboardingDestination.self) { destination in
				switch destination {
				case let .addNewServer(type):
					switch type {
					case .deluge:
						AddDelugeServerView<OnboardingRouter>()
					case .qbittorrent:
						AddQBittorrentServerView<OnboardingRouter>()
					}
				}
			}
	}
}

extension View {
	func withOnboardingDestinations() -> some View {
		modifier(OnboardingDestinationModifier())
	}
}
