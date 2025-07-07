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
final class OnboardingRouter: RouterProtocol {
	typealias Destination = OnboardingDestination
	typealias Sheet = OnboardingSheet

	var path: [OnboardingDestination] = []
	var presentedSheet: OnboardingSheet? = nil
	let parent: (any RouterProtocol)?

	required init(_ parent: (any RouterProtocol)? = nil) {
		self.parent = parent
	}
}
