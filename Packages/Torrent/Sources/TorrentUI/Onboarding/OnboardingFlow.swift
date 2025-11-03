//
//  OnboardingFlow.swift
//  Magnesium
//
//  Created by ninji on 13/06/2025.
//
import SwiftUI
import Router

struct OnboardingFlow: Flow {
	typealias Router = OnboardingRouter

	@State var router: OnboardingRouter

	@Binding var preferences: TorrentPreferences
	@Binding var session: TorrentSession

	var body: some View {
		NavigationStack(path: $router.path) {
			OnboardingView()
				.withOnboardingDestinations()
				.withOnboardingSheets(router: $router, preferences: $preferences, session: $session)
		}
		.withOnboardingErrors(router: $router)
		.environment(router)
		.environment(preferences)
		.environment(session)
	}
}
