//
//  AppFlow.swift
//  Magnesium
//
//  Created by ninji on 03/11/2025.
//

import SwiftUI
import Router

struct AppFlow: Flow {
	typealias Router = AppRouter

	@State var router: AppRouter

	var body: some View {
		NavigationStack(path: $router.path) {
			AppView()
				.withAppDestinations()
		}
		.environment(router)
	}
}
