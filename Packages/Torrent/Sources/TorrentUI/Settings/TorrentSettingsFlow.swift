//
//  TorrentSettingsFlow.swift
//  Torrent
//
//  Created by ninji on 06/10/2025.
//

import SwiftUI
import Router

public struct TorrentSettingsFlow: Flow {
	public typealias Router = TorrentSettingsRouter

	let preferences: TorrentPreferences
	let session: TorrentSession

// TODO: Fix plz
	@State public  var router: TorrentSettingsRouter

	public var body: some View {
//		NavigationStack(path: $router.path) {
		Group {
			TorrentSettingsListView()
				.withTorrentSettingsDestinations(router: router, session: session, preferences: preferences)
		}
		.environment(router)
		.environment(preferences)
		.environment(session)
	}
}
