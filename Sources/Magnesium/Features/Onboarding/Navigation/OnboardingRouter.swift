//
//  OnboardingRouter.swift
//  Magnesium
//
//  Created by ninji on 13/06/2025.
//

import Observation
import Router

/// Router for the Onboarding feature flow.
///
/// Handles navigation during the initial app setup process for server
/// configuration.
@Observable
final class OnboardingRouter: Routable {
	typealias Destination = OnboardingDestination
	typealias Sheet = OnboardingSheet
	typealias Error = OnboardingError

	var path: [Destination] = []
	var presentedSheet: Sheet? = nil
	var presentedError: Error? = nil
	let parent: (any Routable)?

	required init(_ parent: (any Routable)? = nil) {
		self.parent = parent
	}
}
