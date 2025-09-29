//
//  SettingsFlow.swift
//  Magnesium
//
//  Created by ninji on 10/05/2025.
//

import SwiftUI
import Torrent

struct SettingsFlow: View {
	@Environment(TorrentPreferences.self) var preferences
	@Environment(Session.self) var session

	@State var settingsRouter: SettingsRouter

	var body: some View {
		NavigationStack(path: $settingsRouter.path) {
			SettingsListView()
				.withSettingsDestinations()
		}
		.environment(settingsRouter)
		.environment(preferences)
		.environment(session)
	}
}
