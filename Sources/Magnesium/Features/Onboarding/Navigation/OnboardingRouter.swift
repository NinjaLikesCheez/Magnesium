//
//  OnboardingRouter.swift
//  Magnesium
//
//  Created by ninji on 03/11/2025.
//
import Observation
import Router
import SwiftUI

/// Handles navigation within the Onboarding screen.
@Observable
final class OnboardingRouter: Routable {
	typealias Destination = OnboardingDestination
	typealias Sheet = OnboardingSheet
	typealias Error = OnboardingError

	var path = NavigationPath()
	var presentedSheet: Sheet? = nil
	var presentedError: Error? = nil
	let parent: (any Routable)?

	required init(_ parent: (any Routable)? = nil) {
		self.parent = parent
	}
}
