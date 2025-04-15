import SwiftUI
import Logging

@main
struct MagnesiumApp: App {
	@State private var session = Session()
	@State private var preferences = Current.preferences

	init() {
		LoggingSystem.bootstrap { label in
			var logger = StreamLogHandler.standardOutput(label: label)
			#if DEBUG
			logger.logLevel = .debug
			#endif
			return logger
		}
	}

	var body: some Scene {
		WindowGroup {
			NavigationStack {
				if session.server == nil {
					OnboardingView()
						.environment(session)
						.environment(preferences)
				} else {
					TorrentListView()
						.environment(session)
						.environment(preferences)
				}
			}
		}
	}
}
