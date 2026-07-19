//
//  TorrentListStatusToolbar.swift
//  Magnesium
//
//  Created by ninji on 09/04/2025.
//

import SwiftUI

struct TorrentListStatusToolbar: ToolbarContent {
	@Environment(TorrentManager.self) private var torrentManager
	@Environment(TorrentPreferences.self) private var preferences

	var body: some ToolbarContent {
		ToolbarItem(placement: .bottomBar) {
			Text("↓ \(torrentManager.totalDownloadSpeed) ↑ \(torrentManager.totalUploadSpeed)")
				.font(.caption)
				.foregroundStyle(.secondary)
				.frame(minWidth: 100)
		}

		ToolbarItemGroup(placement: .bottomBar) {
			TorrentFilterMenu(labels: torrentManager.labels)
				.environment(preferences)
		}
	}
}
