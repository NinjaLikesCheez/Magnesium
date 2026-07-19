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

	@Binding var isSearching: Bool

	@FocusState private var isSearchFieldFocused: Bool

	var body: some ToolbarContent {
		if #available(iOS 26.0, macOS 26.0, tvOS 26.0, visionOS 26.0, *) {
			glassToolbar
		} else {
			oldGrandpaToolbar
		}
	}

	@available(iOS 26, macOS 26, tvOS 26, visionOS 26, *)
	@ToolbarContentBuilder
	var glassToolbar: some ToolbarContent {
		if isSearching {
			ToolbarItem(placement: .bottomBar) {
				searchField
			}

			ToolbarItem(placement: .bottomBar) {
				Button("Cancel") {
					endSearching()
				}
			}
		} else {
			ToolbarItem(placement: .bottomBar) {
				Text("↓ \(torrentManager.totalDownloadSpeed) ↑ \(torrentManager.totalUploadSpeed)")
					.font(.caption)
					.foregroundStyle(.secondary)
					.frame(minWidth: 100)
			}

			ToolbarSpacer(.flexible, placement: .bottomBar)

			ToolbarItemGroup(placement: .bottomBar) {
				TorrentFilterMenu(labels: torrentManager.labels)
					.environment(preferences)

				searchButton
			}
		}
	}

	@ToolbarContentBuilder
	var oldGrandpaToolbar: some ToolbarContent {
		if isSearching {
			ToolbarItem(placement: .bottomBar) {
				HStack {
					searchField

					Button("Cancel") {
						endSearching()
					}
				}
			}
		} else {
			ToolbarItem(placement: .bottomBar) {
				HStack {
					TorrentFilterMenu(labels: torrentManager.labels)
						.environment(preferences)

					Spacer()

					Text("↓ \(torrentManager.totalDownloadSpeed) ↑ \(torrentManager.totalUploadSpeed)")
						.font(.caption)
						.foregroundStyle(.secondary)
						.frame(minWidth: 100)

					Spacer()

					searchButton
				}
			}
		}
	}

	private var searchField: some View {
		@Bindable var torrentManager = torrentManager

		return HStack {
			Image(systemName: "magnifyingglass")
				.foregroundStyle(.secondary)

			TextField("Search", text: $torrentManager.searchQuery)
				.focused($isSearchFieldFocused)
		}
		.onAppear { isSearchFieldFocused = true }
	}

	private var searchButton: some View {
		Button {
			withAnimation {
				isSearching = true
			}
		} label: {
			Image(systemName: "magnifyingglass")
		}
	}

	private func endSearching() {
		withAnimation {
			isSearching = false
			torrentManager.searchQuery = ""
		}
	}
}
