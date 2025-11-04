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

	@Binding var preferences: TorrentPreferences
	@Binding var session: TorrentSession

// TODO: Fix plz
	@State public  var router: TorrentSettingsRouter = .init()

	public var body: some View {
		NavigationStack(path: $router.path) {
			TorrentSettingsListView()
				.withTorrentSettingsDestinations()
		}
		.environment(router)
		.environment(preferences)
		.environment(session)
	}
}
