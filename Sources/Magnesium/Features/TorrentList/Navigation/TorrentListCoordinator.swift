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

	var body: some View {
		@Bindable var router = router

		TorrentListView()
			.navigationDestination(for: Destinations.self) { destination in
				switch destination {
				case let .detail(torrent):
					TorrentDetailView(torrent: torrent)
						.environment(dependencies.session.actionImplementation)
				}
			}
			.sheet(item: $router.presentedSheet) { item in
				if let sheet = item.destination as? Sheets {
					switch sheet {
					case let .filter(labels):
						TorrentFilterSettingsView(labels: labels)
							.presentationDetents([.height(400), .medium, .large])
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

		case filter(labels: [StandardLabel])
		case settings
	}
}
