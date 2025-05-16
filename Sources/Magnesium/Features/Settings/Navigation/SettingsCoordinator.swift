//
//  SettingsCoordinator.swift
//  Magnesium
//
//  Created by ninji on 10/05/2025.
//

import SwiftUI

struct SettingsCoordinator: Coordinator {
	let dependencies: Dependencies
	@Environment(Router.self) var router

	init(dependencies: Dependencies) {
		self.dependencies = dependencies
	}

	var body: some View {
		@Bindable var router = router
		NavigationStack(path: $router.path) {
			SettingsView()
				.navigationDestination(for: Destinations.self) { item in
					switch item {
					case .addAServer:
						AddServerView()
					case let .addNewServer(type):
						switch type {
						case .deluge:
							AddDelugeServerView()
						case .qbittorrent:
							AddQBittorrentServerView()
						}
					case let .editServer(server):
						switch server.type {
						case .deluge:
							EditDelugeServerView(server)
						case .qbittorrent:
							fatalError("Not yet implemnented")
						}
					}
				}
		}
		.environment(router)
		.environment(dependencies.preferences)
		.environment(dependencies.session)
	}
}

extension SettingsCoordinator {
	struct Dependencies {
		let preferences: AppPreferences
		let session: Session
	}

	enum Destinations: Hashable {
		case editServer(Server)
		case addAServer
		case addNewServer(ServerType)
	}

	enum Sheets: Hashable, Identifiable {
		var id: ObjectIdentifier { self }
	}
}

extension Router {
	func push(_ destination: SettingsCoordinator.Destinations) {
		path.append(destination)
	}
}
