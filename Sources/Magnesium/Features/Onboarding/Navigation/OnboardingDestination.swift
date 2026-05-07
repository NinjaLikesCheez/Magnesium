//
//  OnboardingDestination.swift
//  Magnesium
//
//  Created by ninji on 03/11/2025.
//

import Router
import SwiftUI

/// Navigation destinations for the Onboarding feature.
enum OnboardingDestination: RoutableDestination {
	var id: Self { fatalError("Not yet implemented") }
}

struct OnboardingDestinationModifier: RoutableDestinationViewModifier {
	func body(content: Content) -> some View {
		content
			.navigationDestination(for: OnboardingDestination.self) { destination in
				switch destination {
				default: fatalError("Not yet implemented")
				}
			}
	}
}

extension View {
	func withOnboardingDestinations() -> some View {
		modifier(OnboardingDestinationModifier())
	}
}
