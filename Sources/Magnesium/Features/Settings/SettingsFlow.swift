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

	@Environment(TorrentPreferences.self) var preferences
	@Environment(TorrentSession.self) var session

	@State var router: SettingsRouter

	var body: some View {
		NavigationStack(path: $router.path) {
			SettingsListView()
				.withSettingsDestinations()
		}
		.environment(router)
		.environment(preferences)
		.environment(session)
	}
}
