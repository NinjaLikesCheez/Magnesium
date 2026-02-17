//
//  CompactTorrentsView.swift
//  Magnesium
//
//  Created by ninji on 25/06/2025.
//

import SwiftUI
import Router
import Common

public struct TorrentsListFlow: Flow {
	public typealias Router = TorrentListRouter

	// TODO: fix plz
	@State public var router: TorrentListRouter = .init()

	let session: TorrentSession
	let preferences: TorrentPreferences
	let manager: TorrentManager

	public var body: some View {
		NavigationStack(path: $router.path) {
			TorrentNavigationView()
				.withTorrentListDestinations(
					manager: manager
				)
				.withTorrentListSheets(
					router: router,
					preferences: preferences,
					session: session
				)
		}
		.withTorrentListErrors(router: $router)
		.environment(manager)
		.environment(router)
		.environment(preferences)
		.environment(session)
	}
}
