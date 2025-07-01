//
//  OnboardingFlow.swift
//  Magnesium
//
//  Created by ninji on 13/06/2025.
//
import SwiftUI

struct OnboardingFlow: View {
	@State var onboardingRouter: OnboardingRouter

	@Binding var preferences: AppPreferences
	@Binding var session: Session

	var body: some View {
		NavigationStack(path: $onboardingRouter.path) {
			OnboardingView()
				.withOnboardingDestinations()
				.withOnboardingSheets(router: $onboardingRouter, preferences: $preferences, session: $session)
		}
		.environment(onboardingRouter)
		.environment(preferences)
		.environment(session)
	}
}
