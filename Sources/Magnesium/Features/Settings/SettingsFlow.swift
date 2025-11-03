//
//  SettingsFlow.swift
//  Magnesium
//
//  Created by ninji on 10/05/2025.
//

import SwiftUI
import TorrentUI
import Router

struct SettingsFlow: Flow {
	typealias Router = SettingsRouter

	@State var router: SettingsRouter

	var body: some View {
		NavigationStack(path: $router.path) {
			SettingsListView()
				.withSettingsDestinations()
		}
		.environment(router)
	}
}
