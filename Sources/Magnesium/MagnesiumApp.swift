import SwiftUI
import Logging

@main
struct MagnesiumApp: App {
	@Environment(\.appRouter) private var router

	@State private var session = Session()
	@State private var preferences = Current.preferences

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
		@Bindable var router = router

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
