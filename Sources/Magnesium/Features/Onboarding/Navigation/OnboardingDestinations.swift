//
//  OnboardingDestination.swift
//  Magnesium
//
//  Created by ninji on 12/06/2025.
//

import SwiftUI

/// Navigation destinations for the Onboarding feature.
/// 
/// Defines all possible push navigation targets within the onboarding flow.
enum OnboardingDestinations: RoutableDestinations {
	var id: Self { self }

	/// Navigate to add a specific server type via push navigation
	case addNewServer(ServerType)
}

struct OnboardingDestinationsModifier: ViewModifier {
	func body(content: Content) -> some View {
		content
			.navigationDestination(for: OnboardingDestinations.self) { destination in
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
		modifier(OnboardingDestinationsModifier())
	}
}
