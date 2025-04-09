//
//  TorrentListStatusToolbar.swift
//  Magnesium
//
//  Created by ninji on 09/04/2025.
//

import SwiftUI

struct TorrentListStatusToolbar: ToolbarContent {
	@Binding var showingFilterView: Bool
	@State var torrents: [StandardTorrent]

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
				showingFilterView = true
			} label: {
				Image(systemName: "line.3.horizontal.decrease.circle")
			}

			Spacer()

			Text("↓ \(totalDownloadSpeed) ↑ \(totalUploadSpeed)")
			.font(.caption)
			.foregroundStyle(.secondary)

			Spacer()

			Menu {
				Button {
					// TODO: Implement file picker
				} label: {
					Text("Add File")
				}
				Button {
					// TODO: Implement link input
				} label: {
					Text("Add Link")
				}
			} label: {
				Image(systemName: "plus")
			}
		}
	}
}
