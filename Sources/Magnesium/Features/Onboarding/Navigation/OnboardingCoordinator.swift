//
//  OnboardingCoordinator.swift
//  Magnesium
//
//  Created by ninji on 10/05/2025.
//

import SwiftUI

struct OnboardingCoordinator: Coordinator {
	let dependencies: Dependencies

	@Environment(Router.self) var router

	init(dependencies: Dependencies) {
		self.dependencies = dependencies
	}

	var body: some View {
		@Bindable var router = router
		OnboardingView()
			.navigationDestination(for: Destinations.self) { item in
				switch item {
				case let .addServer(server):
					switch server {
					case .deluge:
						AddDelugeServerView()
							.environment(dependencies.preferences)
					case .qbittorrent:
						fatalError("Not yet implemented")
					}
				}
			}
			.sheet(item: $router.presentedSheet) { item in
				NavigationStack {
					switch item.destination as? OnboardingCoordinator.Sheets {
					case let .addServer(server):
						switch server {
						case .deluge:
							AddDelugeServerView()
								.environment(dependencies.preferences)
						case .qbittorrent:
							fatalError("Not yet implemented")
						}
					case .none:
						fatalError("Sheets presented from inside OnboardingCoordinator are expected to be of type OnboardingCoordinator.Sheets")
					}
				}
			}
			.environment(router)
	}
}

extension OnboardingCoordinator {
	struct Dependencies {
		let preferences: AppPreferences
	}

	enum Destinations: Hashable {
		case addServer(ServerType)
	}

	enum Sheets: Hashable, Identifiable {
		var id: Self { self }

		case addServer(ServerType)
	}
}

extension Router {
	func push(_ destination: OnboardingCoordinator.Destinations) {
		path.append(destination)
	}

	func sheet(_ sheet: OnboardingCoordinator.Sheets) {
		presentedSheet = .init(sheet)
	}
}
