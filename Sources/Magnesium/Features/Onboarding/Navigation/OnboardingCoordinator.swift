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
		var id: ObjectIdentifier { self }
	}
}

extension Router {
	func push(_ destination: OnboardingCoordinator.Destinations) {
		path.append(destination)
	}
}
