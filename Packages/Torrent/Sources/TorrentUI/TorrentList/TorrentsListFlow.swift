//
//  CompactTorrentsView.swift
//  Magnesium
//
//  Created by ninji on 25/06/2025.
//

import SwiftUI
import SwiftUINavigation
import Common
import CommonUI

public struct TorrentsListFlow: View {
	@State public var model: TorrentListModel = .init()

	let session: TorrentSession
	let preferences: TorrentPreferences
	let manager: TorrentManager

	public init(session: TorrentSession, preferences: TorrentPreferences, manager: TorrentManager) {
		self.session = session
		self.preferences = preferences
		self.manager = manager
	}

	public var body: some View {
		@Bindable var model = model

		TorrentNavigationView()
			.navigationDestination(item: $model.destination.detail) { $torrent in
				TorrentDetailView(torrent: torrent)
					.environment(manager)
			}
		.panel(item: $model.error.clientError) { error in
			ErrorPanelCard(
				error: error,
				primaryButtonAction: { model.error = nil }
			)
		}
		.panel(item: $model.error.fileImportError) { error in
			PanelCard(
				title: "File Import Error",
				systemName: "square.and.arrow.down.badge.xmark",
				subtitle: error.message,
				primaryButtonAction: { model.error = nil }
			)
		}
		.environment(manager)
		.environment(model)
		.environment(preferences)
		.environment(session)
	}
}
