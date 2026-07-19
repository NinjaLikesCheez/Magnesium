//
//  TorrentListCoordinator.swift
//  Magnesium
//
//  Created by ninji on 10/05/2025.
//

import SwiftUI

struct TorrentNavigationView: View {
	@Environment(TorrentManager.self) var torrentManager
	@Environment(\.horizontalSizeClass) private var horizontalSizeClass

	// BEWARE: this needs to be whatever the id of StandardTorrent is. Otherwise, SwiftUI will not show editing multiselect!
	@State private var selections: Set<String> = []
	@State private var columnVisibility: NavigationSplitViewVisibility = .all
	@State private var editMode: EditMode = .inactive
	@State private var isSearching: Bool = false

	var selectedTorrents: Set<StandardTorrent> {
		Set(torrentManager.filteredTorrents.filter { selections.contains($0.id) })
	}

	var body: some View {
		if horizontalSizeClass == .compact {
			contentView
		} else {
			splitView
		}
	}

	var contentView: some View {
		TorrentListView(selections: $selections, editMode: $editMode)
			.toolbar {
				selectToolbarItem

				#if os(iOS) || os(tvOS) || os(visionOS)
					if #available(iOS 26.0, tvOS 26.0, visionOS 26.0, *) {
						ToolbarSpacer(.fixed, placement: .topBarTrailing)
					}
				#endif

				addTorrentToolbarItem

				if editMode.isEditing {
					TorrentListEditingToolbar(
						editMode: $editMode,
						selectedTorrents: selectedTorrents
					)
				} else {
					TorrentListStatusToolbar(
						isSearching: $isSearching
					)
				}
			}
	}

	var splitView: some View {
		NavigationSplitView {
			contentView
		} detail: {
			if selections.isEmpty {
				ContentUnavailableView(
					"No selection",
					systemImage: "filemenu.and.selection",
					description: Text("Select a torrent to see details about it")
				)
			} else if let torrent = selectedTorrents.first {
				TorrentDetailView(
					torrent: torrent
				)
			} else {
				ContentUnavailableView(
					"Multiple selections",
					systemImage: "filemenu.and.selection",
					description: Text("Select a single torrent to see details about it")
				)
			}
		}
		.navigationSplitViewStyle(.balanced)
	}

	@ToolbarContentBuilder
	var addTorrentToolbarItem: some ToolbarContent {
		#if os(macOS)
			ToolbarItem(placement: .primaryAction) {
				AddTorrentButton()
			}
		#else
			ToolbarItem(placement: .topBarTrailing) {
				AddTorrentButton()
			}
		#endif
	}

	@ToolbarContentBuilder
	var selectToolbarItem: some ToolbarContent {
		#if os(macOS)
			ToolbarItem(placement: .primaryAction) {
				// EditButton()
				// ^ This doesn't work... because Apple are a small scale start up that can't possibly be expected to make working software
				Button(editMode.isEditing ? "Done" : "Select") {
					withAnimation {
						editMode = editMode.isEditing ? .inactive : .active
					}
				}
			}
		#else
			ToolbarItem(placement: .topBarTrailing) {
				// EditButton()
				// ^ This doesn't work... because Apple are a small scale start up that can't possibly be expected to make working software
				Button(editMode.isEditing ? "Done" : "Select") {
					withAnimation {
						editMode = editMode.isEditing ? .inactive : .active
					}
				}
			}
		#endif
	}
}
