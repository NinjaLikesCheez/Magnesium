import SwiftUI
import Logging

@main
struct MagnesiumApp: App {
	@State private var session = Session()
	@State private var preferences = Current.preferences
	@State private var router = Router("App Router")

	init() {
		LoggingSystem.bootstrap { label in
			var logger = StreamLogHandler.standardOutput(label: label)
//			#if DEBUG
//			logger.logLevel = .debug
//			#endif
			return logger
		}
	}

	var body: some Scene {
		WindowGroup {
			NavigationStack(path: $router.path) {
				if session.server == nil {
					OnboardingCoordinator(
						dependencies: .init(preferences: preferences)
					)
				} else {
					TorrentListCoordinator(
						dependencies: .init(
							preferences: preferences,
							session: session
						)
					)
				}
			}
			.environment(router)
		}
	}
}
