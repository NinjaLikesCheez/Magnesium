//
//  TorrentListCoordinator.swift
//  Magnesium
//
//  Created by ninji on 10/05/2025.
//

import SwiftUI

struct TorrentNavigationView: View {
	@Environment(TorrentListRouter.self) var router
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
		@Bindable var router = router
		@Bindable var torrentManager = torrentManager

		if horizontalSizeClass == .compact {
			contentView
		} else {
			splitView
		}
	}

	var contentView: some View {
		TorrentListView(selections: $selections, editMode: $editMode)
			.toolbar {
				settingsToolbarItem

				selectToolbarItem

				if editMode.isEditing {
					TorrentListEditingToolbar(
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

	var settingsToolbarItem: some ToolbarContent {
		ToolbarItem(placement: .topBarLeading) {
			Button {
				router.presentSheet(.settings)
			} label: {
				Image(systemName: "gear")
			}
		}
	}

	@ToolbarContentBuilder
	var selectToolbarItem: some ToolbarContent {
		ToolbarItem(placement: .topBarTrailing) {
			// EditButton()
			// ^ This doesn't work... because Apple are a small scale start up that can't possibly be expected to make working software
			Button(editMode.isEditing ? "Done" : "Select") {
				withAnimation {
					editMode = editMode.isEditing ? .inactive : .active
				}
			}
		}
	}
}
