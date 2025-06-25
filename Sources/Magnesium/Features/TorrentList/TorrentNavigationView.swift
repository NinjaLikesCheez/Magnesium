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

	@State private var selections: Set<String> = []
	@State private var columnVisibility: NavigationSplitViewVisibility = .all

	var body: some View {
		@Bindable var router = router
		@Bindable var torrentManager = torrentManager

		if horizontalSizeClass == .compact {
			contentView
		} else {
			regularView
		}
	}

	var contentView: some View {
		TorrentListView(selections: $selections)
			.toolbar {
				settingsToolbarItem
			}
	}

	var regularView: some View {
		NavigationSplitView {
			contentView
		} detail: {
			if selections.isEmpty {
				ContentUnavailableView(
					"No selection",
					systemImage: "filemenu.and.selection",
					description: Text("Select a torrent to see details about it")
				)
			} else if selections.count == 1 {
				TorrentDetailView(
					torrent: torrentManager.torrents.first(where: { $0.id == selections.first! })!
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
}

