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
			// Safe here because search sits in the bottom bar (see `searchToolbarItem`): minimize collapses
			// search into a trailing button that expands on tap, without touching the top-bar items (#69).
			#if !os(tvOS)
				.searchToolbarBehavior(.minimize)
			#endif
			.toolbar {
				selectToolbarItem

				if !editMode.isEditing {
					topBarTrailingSpacer
					addTorrentToolbarItem
				}

				searchToolbarItem

				if editMode.isEditing {
					TorrentListEditingToolbar(
						editMode: $editMode,
						selectedTorrents: selectedTorrents
					)
				} else {
					TorrentListStatusToolbar()
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

	/// Keeps Select and Add rendering as two distinct glass controls instead of merging into one pill.
	@ToolbarContentBuilder
	var topBarTrailingSpacer: some ToolbarContent {
		#if os(macOS)
			ToolbarSpacer(.fixed, placement: .primaryAction)
		#else
			ToolbarSpacer(.fixed, placement: .topBarTrailing)
		#endif
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

	/// Relocates the system search field to the bottom bar so it no longer collapses `selectToolbarItem`
	/// (the root cause of #69 was `.searchToolbarBehavior(.minimize)` while search lived in the top bar —
	/// in the bottom bar, minimize only collapses search itself, see `contentView`).
	/// The leading flexible spacer pushes the minimized search button to the trailing edge.
	/// Unavailable on tvOS, so `.searchable` falls back to its default placement there.
	@ToolbarContentBuilder
	var searchToolbarItem: some ToolbarContent {
		#if !os(tvOS)
			ToolbarSpacer(.flexible, placement: .bottomBar)
			DefaultToolbarItem(kind: .search, placement: .bottomBar)
		#endif
	}
}
