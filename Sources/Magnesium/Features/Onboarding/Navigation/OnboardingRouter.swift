//
//  OnboardingRouter.swift
//  Magnesium
//
//  Created by ninji on 13/06/2025.
//
import Observation

/// Router for the Onboarding feature flow.
/// 
/// Handles navigation during the initial app setup process for server
/// configuration and account setup workflows.
@Observable
final class OnboardingRouter: RouterProtocol {
	typealias Destination = OnboardingDestinations
	typealias Sheet = OnboardingSheets

	var path: [OnboardingDestinations] = []
	var presentedSheet: OnboardingSheets? = nil
	let parent: (any RouterProtocol)?

	required init(_ parent: (any RouterProtocol)? = nil) {
		self.parent = parent
	}
}
