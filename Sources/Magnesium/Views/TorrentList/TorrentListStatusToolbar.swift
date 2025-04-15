//
//  TorrentListStatusToolbar.swift
//  Magnesium
//
//  Created by ninji on 09/04/2025.
//

import SwiftUI

struct TorrentListStatusToolbar: ToolbarContent {
	@Environment(Session.self) private var session

	@State var torrents: [StandardTorrent]
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
						let _ = URL(string: string)
				else {
					showAddTorrentConfirmation = true
					return
				}

				Task {
					try await session.actionImplementation.addLink(string)
				}
			} label: {
				Image(systemName: "plus")
			}
		}
	}
}
