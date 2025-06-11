import SwiftUI
import Logging

@main
struct MagnesiumApp: App {
	@Environment(\.appRouter) private var router

	let session = Session()
	let preferences = AppPreferences(userDefaults: .standard)

	@State private var torrentManager: TorrentManager

	init() {
		LoggingSystem.bootstrap { label in
			var logger = StreamLogHandler.standardOutput(label: label)
			#if DEBUG
			logger.logLevel = .debug
			#endif
			return logger
		}
		_torrentManager = State(wrappedValue: TorrentManager(session: session))
	}

	var body: some Scene {
		@Bindable var router = router

		WindowGroup {
			Group {
				if session.server == nil {
					NavigationStack(path: $router.path) {
						OnboardingCoordinator(
							dependencies: .init(preferences: preferences)
						)
					}
				} else {
					TorrentListCoordinator(
						dependencies: .init(
							preferences: preferences,
							session: session
						)
					)
					.environment(torrentManager)
				}
			}
			.environment(router)
		}
	}
}
