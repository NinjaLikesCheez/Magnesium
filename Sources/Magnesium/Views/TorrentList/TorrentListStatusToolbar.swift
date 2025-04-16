//
//  TorrentListStatusToolbar.swift
//  Magnesium
//
//  Created by ninji on 09/04/2025.
//

import SwiftUI

struct TorrentListStatusToolbar: ToolbarContent {
	@Environment(Session.self) private var session

	@Binding var torrents: [StandardTorrent]
	@Binding var sheetDestination: SheetDestination?
	@Binding var showAddTorrentConfirmation: Bool

	private var totalUploadSpeed: String {
		Formatters.bytes.string(fromByteCount: torrents.reduce(into: 0) { $0 += $1.uploadRate })
	}

	private var totalDownloadSpeed: String {
		Formatters.bytes.string(fromByteCount: torrents.reduce(into: 0) { $0 += $1.downloadRate })
	}

	var body: some ToolbarContent {
		ToolbarItem(placement: .bottomBar) {
			items
		}
	}

	var items: some View {
		HStack {
			Button {
				sheetDestination = .filter
			} label: {
				Image(systemName: "line.3.horizontal.decrease.circle")
			}

			Spacer()

			Text("↓ \(totalDownloadSpeed) ↑ \(totalUploadSpeed)")
			.font(.caption)
			.foregroundStyle(.secondary)

			Spacer()

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
	}
}
