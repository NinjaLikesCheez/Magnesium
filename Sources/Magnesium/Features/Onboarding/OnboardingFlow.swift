//
//  OnboardingFlow.swift
//  Magnesium
//
//  Created by ninji on 13/06/2025.
//
import SwiftUI
import TorrentUI

struct OnboardingFlow: View {
	@State var onboardingRouter: OnboardingRouter

	@Binding var preferences: TorrentPreferences
	@Binding var session: TorrentSession

	var body: some View {
		NavigationStack(path: $onboardingRouter.path) {
			OnboardingView()
				.withOnboardingDestinations()
				.withOnboardingSheets(router: $onboardingRouter, preferences: $preferences, session: $session)
		}
		.withOnboardingErrors(router: $onboardingRouter)
		.environment(onboardingRouter)
		.environment(preferences)
		.environment(session)
	}
}
