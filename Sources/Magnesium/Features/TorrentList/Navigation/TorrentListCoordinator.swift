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

	@State private var torrents: [StandardTorrent] = []
	@State private var labels: [StandardLabel] = []
	@State private var searchQuery: String = ""
	@State private var error: String?

	@State private var selections: Set<String> = []
	@State private var columnVisibility: NavigationSplitViewVisibility = .doubleColumn

	var body: some View {
		@Bindable var router = router

		NavigationSplitView(columnVisibility: $columnVisibility) {
			TorrentListView(torrents: $torrents, labels: $labels, searchQuery: $searchQuery, error: $error, selections: $selections)
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
			if selections.isEmpty {
				ContentUnavailableView(
					"No selection",
					systemImage: "filemenu.and.selection",
					description: Text("Select a torrent to see details about it")
				)
			} else if selections.count == 1 {
				TorrentDetailView(torrent: torrents.first(where: { $0.id == selections.first! })!)
					.environment(dependencies.session.actionImplementation)
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

	func refresh() {
		Task {
			do {
				let (torrents, labels) = try await dependencies.session.actionImplementation.refresh()
				error = nil
				
				self.torrents = TorrentMapper
					.map(
						torrents,
						query: searchQuery,
						sortOption: dependencies.preferences.sortOption,
						filterOptions: dependencies.preferences.filterOptions
					)
				self.labels = labels
			} catch {
				print("Error refreshing torrents: \(error)")
				self.error = error.localizedDescription
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
