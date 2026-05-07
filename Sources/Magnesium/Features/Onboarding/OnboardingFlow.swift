//
//  OnboardingFlow.swift
//  Magnesium
//
//  Created by ninji on 03/11/2025.
//

import SwiftUI
import Router

struct OnboardingFlow: Flow {
	typealias Router = OnboardingRouter

	@State var router: OnboardingRouter

	var body: some View {
		NavigationStack(path: $router.path) {
			OnboardingListView()
				.withOnboardingDestinations()
		}
		.environment(router)
	}
}
