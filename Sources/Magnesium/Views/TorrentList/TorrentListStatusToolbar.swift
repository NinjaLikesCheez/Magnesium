//
//  TorrentListStatusToolbar.swift
//  Magnesium
//
//  Created by ninji on 09/04/2025.
//

import SwiftUI

struct TorrentListStatusToolbar: ToolbarContent {
	@Environment(Session.self) private var session
	@Environment(AppRouter.self) private var router
	@Environment(AppPreferences.self) private var preferences

	var torrents: [StandardTorrent]
	var labels: [StandardLabel]
	@Binding var showAddTorrentConfirmation: Bool

	private var totalUploadSpeed: String {
		Formatters.bytes.string(fromByteCount: torrents.reduce(into: 0) { $0 += $1.uploadRate })
	}

	private var totalDownloadSpeed: String {
		Formatters.bytes.string(fromByteCount: torrents.reduce(into: 0) { $0 += $1.downloadRate })
	}

	var body: some ToolbarContent {
		ToolbarItemGroup(placement: .bottomBar) {
			TorrentFilterMenu(labels: labels)
				.environment(preferences)

			Button {
				guard
					Current.preferences.automaticallyLookForMagnetLinks,
					let string = UIPasteboard.general.string,
					let url = URL(string: string),
					url.scheme == "magnet"
				else {
					showAddTorrentConfirmation = true
					return
				}

				Task {
					do {
						try await session.actionImplementation.addLink(string)
					} catch {
						// TODO: Error handle
						showAddTorrentConfirmation = true
					}
				}
			} label: {
				Image(systemName: "plus")
			}
		}

		ToolbarSpacer(.flexible, placement: .bottomBar)

		ToolbarItem(placement: .bottomBar) {
			Text("↓ \(totalDownloadSpeed) ↑ \(totalUploadSpeed)")
				.font(.caption)
				.foregroundStyle(.secondary)
				.frame(minWidth: 100)
		}
	}
}
