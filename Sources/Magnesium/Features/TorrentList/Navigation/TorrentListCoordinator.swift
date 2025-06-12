//
//  TorrentListCoordinator.swift
//  Magnesium
//
//  Created by ninji on 10/05/2025.
//

import SwiftUI

struct TorrentListCoordinator: Coordinator {
	let dependencies: Dependencies

	init(dependencies: Dependencies) {
		self.dependencies = dependencies
	}

	@Environment(Router.self) var router
	@State var settingsRouter = Router("Settings Router")

	@Environment(TorrentManager.self) var torrentManager
	@Environment(\.horizontalSizeClass) private var horizontalSizeClass

	@State private var selections: Set<String> = []
	@State private var columnVisibility: NavigationSplitViewVisibility = .automatic

	var body: some View {
		@Bindable var router = router
		@Bindable var torrentManager = torrentManager

		NavigationSplitView(columnVisibility: $columnVisibility) {
			TorrentListView(
				selections: $selections
			)
			.sheet(item: $router.presentedSheet) { item in
				if let sheet = item.destination as? Sheets {
					switch sheet {
					case .settings:
						SettingsCoordinator(
							dependencies: .init(
								preferences: dependencies.preferences,
								session: dependencies.session
							)
						)
						.environment(settingsRouter)
					}
				}
			}
			.environment(dependencies.session)
			.environment(dependencies.preferences)
		} detail: {
			Group {
				if selections.isEmpty {
					ContentUnavailableView(
						"No selection",
						systemImage: "filemenu.and.selection",
						description: Text("Select a torrent to see details about it")
					)
				} else if selections.count == 1 {
					TorrentDetailView(torrent: torrentManager.torrents.first(where: { $0.id == selections.first! })!)
						.environment(dependencies.session.actionImplementation)
				} else {
					ContentUnavailableView(
						"Multiple selections",
						systemImage: "filemenu.and.selection",
						description: Text("Select a single torrent to see details about it")
					)
				}
			}
		}
		.navigationSplitViewStyle(.balanced)
	}

	var settingsToolbarItem: some ToolbarContent {
		ToolbarItem(placement: .topBarLeading) {
			Button {
				router.present(TorrentListCoordinator.Sheets.settings)
			} label: {
				Image(systemName: "gear")
			}
		}
	}
}

extension TorrentListCoordinator {
	struct Dependencies {
		let preferences: AppPreferences
		let session: Session
	}

	enum Destinations: Hashable {
		case detail(StandardTorrent)
	}

	enum Sheets: Hashable, Identifiable {
		var id: Self { self }

		case settings
	}
}

extension Router {
	func push(_ destination: TorrentListCoordinator.Destinations) {
		path.append(destination)
	}
}
