//
//  CompactTorrentsView.swift
//  Magnesium
//
//  Created by ninji on 25/06/2025.
//

import SwiftUI

struct TorrentsListFlow: View {
	@State var torrentListRouter: TorrentListRouter

	@Binding var torrentManager: TorrentManager
	@Binding var preferences: AppPreferences
	@Binding var session: Session

	var body: some View {
		NavigationStack(path: $torrentListRouter.path) {
			TorrentsView()
				.withTorrentListDestinations()
				.withTorrentListSheets(
					router: $torrentListRouter,
					preferences: $preferences,
					session: $session
				)
				.environment(torrentManager)
		}
		.environment(torrentListRouter)
		.environment(preferences)
		.environment(session)
	}
}
