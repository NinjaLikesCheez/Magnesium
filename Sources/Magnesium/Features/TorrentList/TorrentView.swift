//
//  TorrentListCoordinator.swift
//  Magnesium
//
//  Created by ninji on 10/05/2025.
//

import SwiftUI

struct TorrentsView: View {
	@Environment(AppRouter.self) var router

//	@State var settingsRouter = Router("Settings Router")

	@Environment(TorrentManager.self) var torrentManager
	@Environment(\.horizontalSizeClass) private var horizontalSizeClass

	@State private var selections: Set<String> = []
	@State private var columnVisibility: NavigationSplitViewVisibility = .all

	var body: some View {
		@Bindable var router = router
		@Bindable var torrentManager = torrentManager

		TorrentListView(selections: $selections)


//		NavigationSplitView(columnVisibility: $columnVisibility) {
//			TorrentListView(
//				selections: $selections
//			)
//		} detail: {
//			Group {
//				if selections.isEmpty {
//					ContentUnavailableView(
//						"No selection",
//						systemImage: "filemenu.and.selection",
//						description: Text("Select a torrent to see details about it")
//					)
//				} else if selections.count == 1 {
//					TorrentDetailView(torrent: torrentManager.torrents.first(where: { $0.id == selections.first! })!)
////						.environment(dependencies.session.actionImplementation)
//				} else {
//					ContentUnavailableView(
//						"Multiple selections",
//						systemImage: "filemenu.and.selection",
//						description: Text("Select a single torrent to see details about it")
//					)
//				}
//			}
//		}
//		.navigationSplitViewStyle(.balanced)
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

